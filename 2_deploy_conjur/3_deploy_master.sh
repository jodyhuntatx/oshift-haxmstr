#!/bin/bash -x
set -eo pipefail

. ../utils.sh

oc login -u $OSHIFT_CONJUR_ADMIN
set_project $CONJUR_PROJECT_NAME

# temporary name - no haproxy
CONJUR_MASTER_CONTAINER_NAME=conjur-master
CONJUR_MASTER_PGSYNC_PORT=5432
CONJUR_MASTER_PGAUDIT_PORT=5433

main() {
  scope launch
  master_network_up
  master_up
#  start_standby conjur2
#  start_standby conjur3
#  haproxy_up
  echo "The Conjur master endpoint is at: $CONJUR_MASTER_HOSTNAME:$CONJUR_MASTER_PORT"
  echo
}

############################
master_network_up() {
  docker network create conjur-master-cluster
}

############################
master_up() {
  echo "-----"
  announce "Initializing Conjur Master"
  docker run -d \
    --name $CONJUR_MASTER_CONTAINER_NAME \
    -p "$CONJUR_MASTER_PORT:443" \
    -p "$CONJUR_MASTER_PGSYNC_PORT:5432" \
    -p "$CONJUR_MASTER_PGAUDIT_PORT:5433" \
    --label role=conjur_node \
    --restart always \
    --security-opt seccomp:unconfined \
    $CONJUR_APPLIANCE_IMAGE

  docker network connect conjur-master-cluster $CONJUR_MASTER_CONTAINER_NAME

  MASTER_ALTNAMES="localhost"
  FOLLOWER_ALTNAMES="conjur-follower,conjur-follower.$CONJUR_PROJECT_NAME.svc.cluster.local"
  docker exec -it $CONJUR_MASTER_CONTAINER_NAME evoke configure master \
		-h $CONJUR_MASTER_HOSTNAME \
		-p $CONJUR_ADMIN_PASSWORD \
   		--master-altnames "$MASTER_ALTNAMES" \
		--follower-altnames "$FOLLOWER_ALTNAMES" \
		$CONJUR_ACCOUNT

#		-j /src/etc/conjur.json	  \

  announce "Caching Certificate from Conjur in ./etc..."

  rm -f ./etc/conjur-$CONJUR_ACCOUNT.pem
					# cache cert for copying to other containers
  docker cp -L $CONJUR_MASTER_CONTAINER_NAME:/opt/conjur/etc/ssl/conjur.pem ./etc/conjur-$CONJUR_ACCOUNT.pem

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

  docker network connect conjur-master-cluster $standby_name
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

  docker network connect conjur-master-cluster conjur-master
}

main $@
