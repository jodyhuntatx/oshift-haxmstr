#!/bin/bash -x
set -eou pipefail

. ../utils.sh

############################
main() {
  if [[ $# != 2 ]]; then
    echo "Usage: $0 <name-of-failed-master-container> <name-of-new-standby>"
    exit -1
  fi
  FAILED_MASTER=$1
  NEW_STANDBY=$2

  # make sure the cluster is healthy 
  wait_till_master_is_responsive 

  delete_failed_master $FAILED_MASTER

  master_container_name=$(get_cluster_leader_name)
  update_master_alias $master_container_name

  echo
  echo "After removing failed master $FAILED_MASTER..."
  set +e
  ./check_cluster.sh $master_container_name
  set -e

  update_cluster_config $master_container_name $FAILED_MASTER $NEW_STANDBY

  echo
  echo "After updating cluster config..."
  set +e
  ./check_cluster.sh $master_container_name
  set -e

  # conjur new standby
  new_standby_up $NEW_STANDBY

  # Reenroll new standby in cluster
  docker exec -it $NEW_STANDBY evoke cluster enroll --reenroll -n $NEW_STANDBY conjur-cluster

  echo
  echo "After adding new standby $NEW_STANDBY..."
  set +e
  ./check_cluster.sh $master_container_name
  set -e
}

############################
delete_failed_master() {
  local failed_master_name=$1; shift

  announce "Deleting failed master $failed_master_name..."

  set +e
  docker stop $failed_master_name
  docker rm $failed_master_name
  set -e
}

############################
update_master_alias() {
  local master_name=$1; shift

  # pause nodes
  conjur_node_list=$(docker ps -f "label=role=conjur_node" --format "{{ .Names }}")
  for i in $conjur_node_list; do
    docker pause $i
  done 

  # disconnect master node from network, then reconnect w/ master alias
  docker network disconnect conjur-master-network $master_name
  docker network connect --alias master --alias $master_name conjur-master-network $master_name

  # Resume the containers 
  for i in $conjur_node_list; do
    docker unpause $i
  done
}

############################
update_cluster_config() {
  local master_name=$1; shift
  local failed_master_name=$1; shift
  local new_standby_name=$1; shift

  # remove old entry in cluster config and add new one
  docker exec $master_name evoke cluster member remove $failed_master_name
  docker exec $master_name evoke cluster member add $new_standby_name
}

############################
new_standby_up() {
  local new_standby_name=$1; shift

  announce "Configuring new standby..."

  mkdir -p tmp
  master_container_name=$(get_cluster_leader_name)
  master_ip=$(docker inspect $master_container_name --format "{{ .NetworkSettings.IPAddress }}")

  docker exec $master_container_name evoke seed standby $new_standby_name $master_container_name > ./tmp/${new_standby_name}-seed.tar

  start_standby $new_standby_name
  configure_standby $new_standby_name $master_ip

  rm -rf tmp

  echo "Starting synchronous replication..."

  docker exec $master_container_name evoke replication sync

  echo "New standby configured."
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

  docker cp ./tmp/${standby_name}-seed.tar $standby_name:/tmp/${standby_name}-seed.tar
    
  docker exec $standby_name evoke unpack seed /tmp/${standby_name}-seed.tar
  docker exec $standby_name evoke configure standby -i $master_ip 
#  -j /etc/conjur.json 

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
