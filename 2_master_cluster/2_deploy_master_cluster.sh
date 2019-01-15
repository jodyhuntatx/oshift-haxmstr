#!/bin/bash 
set -eo pipefail

. ../utils.sh

HAPROXY_CONTAINER_NAME=conjur-haproxy

main() {
  scope launch
  master_network_up
  master_up
  start_standbys
  haproxy_up
  cli_up
  cluster_up
  configure_standbys
  announce "The Conjur master endpoint is at: $CONJUR_MASTER_HOST_NAME:$CONJUR_MASTER_PORT"
  echo
}

############################
master_network_up() {
  docker network create $CONJUR_NETWORK
}

############################
master_up() {
  echo "-----"
  announce "Initializing Conjur Master"
  docker run -d \
    --name $CONJUR_MASTER_CONTAINER_NAME \
    --label role=conjur_node \
    --restart always \
    --security-opt seccomp:unconfined \
    $CONJUR_APPLIANCE_IMAGE

  docker network connect $CONJUR_NETWORK $CONJUR_MASTER_CONTAINER_NAME

  docker exec -it $CONJUR_MASTER_CONTAINER_NAME \
    evoke configure master \
    -h $CONJUR_MASTER_HOST_NAME \
    -p $CONJUR_ADMIN_PASSWORD \
    --master-altnames "$MASTER_ALTNAMES" \
    --follower-altnames "$FOLLOWER_ALTNAMES" \
    $CONJUR_ACCOUNT

  echo "Caching Certificate from Conjur in ../etc..."
  mkdir -p ../etc
  rm -f ../etc/conjur-$CONJUR_ACCOUNT.pem
					# cache cert for copying to other containers
  docker cp -L $CONJUR_MASTER_CONTAINER_NAME:/opt/conjur/etc/ssl/conjur.pem ../etc/conjur-$CONJUR_ACCOUNT.pem

  echo "Caching Conjur Follower seed files in ../etc..."
  docker exec $CONJUR_MASTER_CONTAINER_NAME evoke seed follower conjur-follower > ../etc/follower-seed.tar
}

############################
start_standbys() {

  announce "Initializing Standbys"

  start_standby $CONJUR_STANDBY1_NAME
  start_standby $CONJUR_STANDBY2_NAME
}

############################
configure_standbys() {
  echo "Preparing standby seed files..."

  mkdir -p tmp
  master_container_name=$(get_master_pod_name)
  master_ip=$(docker inspect $master_container_name --format "{{ .NetworkSettings.IPAddress }}")

  docker exec $master_container_name evoke seed standby $CONJUR_STANDBY1_NAME $master_container_name > ./tmp/${CONJUR_STANDBY1_NAME}-seed.tar
  configure_standby $CONJUR_STANDBY1_NAME $master_ip

  docker exec $master_container_name evoke seed standby $CONJUR_STANDBY2_NAME $master_container_name > ./tmp/${CONJUR_STANDBY2_NAME}-seed.tar
  configure_standby $CONJUR_STANDBY2_NAME $master_ip

#  rm -rf tmp

  echo "Starting synchronous replication..."

  docker exec $master_container_name evoke replication sync

  echo "Standbys configured."
}  

############################
start_standby() {
  local standby_name=$1; shift

  echo "-----"
  announce "Starting Conjur Standby $standby_name"
  docker run -d \
    --name $standby_name \
    --label role=conjur_node \
    --restart always \
    --security-opt seccomp:unconfined \
    $CONJUR_APPLIANCE_IMAGE

  docker network connect $CONJUR_NETWORK $standby_name
}

############################
configure_standby() {
  local standby_name=$1; shift
  local master_ip=$1; shift

  printf "Configuring standby %s...\n" $standby_name

  docker cp ./tmp/${standby_name}-seed.tar $standby_name:/tmp/${standby_name}-seed.tar
    
  docker exec $standby_name evoke unpack seed /tmp/${standby_name}-seed.tar
  docker exec $standby_name evoke configure standby -i $master_ip

  # enroll standby node in etcd cluster
  docker exec -it $standby_name evoke cluster enroll -n $standby_name conjur-cluster
}

############################
haproxy_up() {
  docker run -d \
    --name $HAPROXY_CONTAINER_NAME \
    --label role=haproxy \
    -p "$CONJUR_MASTER_PORT:443" \
    -p "$CONJUR_MASTER_PGSYNC_PORT:5432" \
    -p "$CONJUR_MASTER_PGAUDIT_PORT:1999" \
    --privileged \
    --restart always \
    --entrypoint "/start.sh" \
    haproxy:latest

  docker network connect $CONJUR_NETWORK $HAPROXY_CONTAINER_NAME

  docker restart $HAPROXY_CONTAINER_NAME
}

############################
cli_up() {

  announce "Creating CLI container."

  start_cli
  configure_cli
}

############################
start_cli() {
  docker run -d \
    --name $CLI_CONTAINER_NAME \
    --label role=cli \
    --restart always \
    --security-opt seccomp:unconfined \
    --entrypoint sh \
    $CLI_IMAGE_NAME \
    -c "sleep infinity" 

  echo "CLI container launched."
}

############################
configure_cli() {
  if [[ $NO_DNS ]]; then
    # add entry to cli container's /etc/hosts so $CONJUR_MASTER_HOST_NAME resolves
    docker exec -it $CLI_CONTAINER_NAME bash -c "echo \"$CONJUR_MASTER_HOST_IP    $CONJUR_MASTER_HOST_NAME\" >> /etc/hosts"
  fi

  wait_till_master_is_responsive
	# initialize cli connection to master & login as admin
  docker exec -it $CLI_CONTAINER_NAME bash -c "echo yes | conjur init -a $CONJUR_ACCOUNT -u https://$CONJUR_MASTER_HOST --force=true"

  docker exec $CLI_CONTAINER_NAME conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD
  docker exec $CLI_CONTAINER_NAME mkdir /policy

  echo "CLI container configured."
}

############################
cluster_up() {
  announce "Initializing etcd cluster..."

  wait_till_master_is_responsive
  docker cp ./cluster-policy.yml conjur-cli:/cluster-policy.yml
  docker exec -it conjur-cli conjur policy load root cluster-policy.yml
  docker exec -it $CONJUR_MASTER_CONTAINER_NAME evoke cluster enroll -n $CONJUR_MASTER_CONTAINER_NAME conjur-cluster

 echo "Cluster initialized."
}

############################
wait_till_master_is_responsive() {
  set +e
  master_is_healthy=""
  while [[ "$master_is_healthy" == "" ]]; do
    sleep 2
    master_is_healthy=$(docker exec -it conjur-cli curl -k https://$CONJUR_MASTER_HOST/health | grep "ok" | tail -1 | grep "true")
  done
  set -e
}

main $@
