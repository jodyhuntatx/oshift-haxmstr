#!/bin/bash 
set -o pipefail

. ../utils.sh

main() {
  scope launch
  master_up
  cli_up
  follower_up
  echo
}

############################
master_up() {
  echo "-----"
  announce "Initializing Conjur Master"
  docker run -d \
    --name $CONJUR_MASTER_CONTAINER_NAME \
    --label role=conjur_node \
    -p "$CONJUR_MASTER_PORT:443" \
    -p "$CONJUR_MASTER_PGSYNC_PORT:5432" \
    -p "$CONJUR_MASTER_PGAUDIT_PORT:1999" \
    --restart always \
    --security-opt seccomp:unconfined \
    $CONJUR_APPLIANCE_IMAGE

  docker exec -it $CONJUR_MASTER_CONTAINER_NAME \
    evoke configure master \
    -h $CONJUR_MASTER_HOST_NAME \
    -p $CONJUR_ADMIN_PASSWORD \
    --master-altnames "$MASTER_ALTNAMES" \
    --follower-altnames "$FOLLOWER_ALTNAMES" \
    $CONJUR_ACCOUNT

  echo "Caching Certificate from Conjur..."
  mkdir -p ../etc
  rm -f ../etc/conjur-$CONJUR_ACCOUNT.pem
					# cache cert for copying to other containers
  docker cp -L $CONJUR_MASTER_CONTAINER_NAME:/opt/conjur/etc/ssl/conjur.pem ../etc/conjur-$CONJUR_ACCOUNT.pem

  echo "Caching Conjur Follower seed files..."
  docker exec $CONJUR_MASTER_CONTAINER_NAME evoke seed follower conjur-follower > ../etc/follower-seed.tar
}

############################
cli_up() {

  announce "Creating CLI container."

  docker run -d \
    --name $CLI_CONTAINER_NAME \
    --label role=cli \
    --restart always \
    --security-opt seccomp:unconfined \
    --entrypoint sh \
    $CLI_IMAGE_NAME \
    -c "sleep infinity" 

  echo "CLI container launched."

  if [[ $NO_DNS ]]; then
    # add entry to cli container's /etc/hosts so $CONJUR_MASTER_HOST_NAME resolves
    docker exec -it $CLI_CONTAINER_NAME bash -c "echo \"$CONJUR_MASTER_HOST_IP    $CONJUR_MASTER_HOST_NAME\" >> /etc/hosts"
  fi

  wait_till_master_is_responsive
	# initialize cli for connection to master
  docker exec -it $CLI_CONTAINER_NAME bash -c "echo yes | conjur init -a $CONJUR_ACCOUNT -u https://$CONJUR_MASTER_HOST --force=true"
  docker exec $CLI_CONTAINER_NAME conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD

  echo "CLI container configured."
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

############################
follower_up() {
  echo "-----"
  announce "Initializing Conjur Follower"
  docker run -d \
    --name conjur_follower \
    --label role=conjur_node \
    -p "$CONJUR_FOLLOWER_PORT:443" \
    --restart always \
    --security-opt seccomp:unconfined \
    $CONJUR_APPLIANCE_IMAGE

  if [[ $NO_DNS ]]; then
    # add entry to follower's /etc/hosts so $CONJUR_MASTER_HOST_NAME resolves
    docker exec -it conjur_follower bash -c "echo \"$CONJUR_MASTER_HOST_IP    $CONJUR_MASTER_HOST_NAME\" >> /etc/hosts"
  fi

  docker cp ../etc/follower-seed.tar conjur_follower:/tmp/follower-seed.tar
  docker exec conjur_follower evoke unpack seed /tmp/follower-seed.tar
  docker exec conjur_follower evoke configure follower -p $CONJUR_MASTER_PORT
}

main $@
