#!/bin/bash 
set -eo pipefail

. ../utils.sh

CONJUR_MASTER_CONTAINER_NAME=conjur1
CONJUR_STANDBY1_NAME=conjur2
CONJUR_STANDBY2_NAME=conjur3
CONJUR_MASTER_PGSYNC_PORT=5432
CONJUR_MASTER_PGAUDIT_PORT=5433

CLI_CONTAINER_NAME=conjur-cli
CLI_IMAGE_NAME=cyberark/conjur-cli:4-latest
CONJUR_MASTER_HOST_IP=127.0.0.1
CONJUR_HOST=$CONJUR_MASTER_HOSTNAME:$CONJUR_MASTER_PORT

main() {
  scope launch
  master_network_up
  master_up
  start_standbys
  haproxy_up
  cli_up
  cluster_up
  configure_standbys
  announce "The Conjur master endpoint is at: $CONJUR_MASTER_HOSTNAME:$CONJUR_MASTER_PORT"
  echo
}

############################
master_network_up() {
  docker network create conjur-master-network
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

  docker network connect conjur-master-network $CONJUR_MASTER_CONTAINER_NAME

  MASTER_ALTNAMES="localhost"
  FOLLOWER_ALTNAMES="conjur-follower,conjur-follower.$CONJUR_PROJECT_NAME.svc.cluster.local"
  docker exec -it $CONJUR_MASTER_CONTAINER_NAME evoke configure master \
		-h $CONJUR_MASTER_HOSTNAME \
		-p $CONJUR_ADMIN_PASSWORD \
   		--master-altnames "$MASTER_ALTNAMES" \
		--follower-altnames "$FOLLOWER_ALTNAMES" \
		$CONJUR_ACCOUNT

  echo "Caching Certificate from Conjur in ./etc..."

  rm -f ./etc/conjur-$CONJUR_ACCOUNT.pem
					# cache cert for copying to other containers
  docker cp -L $CONJUR_MASTER_CONTAINER_NAME:/opt/conjur/etc/ssl/conjur.pem ./etc/conjur-$CONJUR_ACCOUNT.pem

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
  docker exec $master_container_name evoke seed standby conjur-node > ./tmp/standby-seed.tar

  configure_standby $CONJUR_STANDBY1_NAME $master_ip
  configure_standby $CONJUR_STANDBY2_NAME $master_ip

  rm -rf tmp

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

  docker network connect conjur-master-network $standby_name
}

############################
configure_standby() {
  local standby_name=$1; shift
  local master_ip=$1; shift

  printf "Configuring standby %s...\n" $standby_name

  docker cp ./tmp/standby-seed.tar $standby_name:/tmp/standby-seed.tar
    
  docker exec $standby_name evoke unpack seed /tmp/standby-seed.tar
  docker exec $standby_name evoke configure standby -i $master_ip
  docker exec -it $standby_name evoke cluster enroll -n $standby_name conjur-cluster
}

############################
haproxy_up() {
  docker run -d \
    --name conjur-master \
    --label role=haproxy \
    -p "$CONJUR_MASTER_PORT:443" \
    -p "$CONJUR_MASTER_PGSYNC_PORT:5432" \
    -p "$CONJUR_MASTER_PGAUDIT_PORT:5433" \
    --restart always \
    --entrypoint "/start.sh" \
    haproxy:latest

  docker network connect conjur-master-network conjur-master
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
	# DNS HACK - not needed if $CONJUR_MASTER_HOSTNAME resolves w/ DNS
	# add entry to cli container's /etc/hosts so conjur-master resolves
  CONJUR_MASTER_HOST_IP=$(ifconfig en0 | grep "inet " | awk '{print $2}')
  docker exec -it $CLI_CONTAINER_NAME bash -c "echo \"$CONJUR_MASTER_HOST_IP    $CONJUR_MASTER_HOSTNAME\" >> /etc/hosts"

        # make sure master is responding
  master_is_healthy=""
  while [[ "$master_is_healthy" != "" ]]; do
    sleep 2
    master_is_healthy=$(docker exec -it conjur-cli curl -k https://$CONJUR_HOST/health | grep "ok" | tail -1 | grep "true")
  done

	# initialize cli for connection to master
  docker exec -it $CLI_CONTAINER_NAME bash -c "echo yes | conjur init -a $CONJUR_ACCOUNT -h $CONJUR_HOST --force=true"
        # configure policy plugin
  docker exec $CLI_CONTAINER_NAME sed -i.bak -e "s#\[\]#\[ policy \]#g" /root/.conjurrc
  docker exec $CLI_CONTAINER_NAME conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD

  echo "CLI container configured."
}

############################
cluster_up() {
  announce "Initializing etcd cluster..."

  docker cp ./cluster-policy.yml conjur-cli:/root/cluster-policy.yml
  docker exec -it conjur-cli conjur policy load --as-group security_admin cluster-policy.yml
  docker exec -it $CONJUR_MASTER_CONTAINER_NAME evoke cluster enroll -n $CONJUR_MASTER_CONTAINER_NAME conjur-cluster

 echo "Cluster initialized."
}

main $@
