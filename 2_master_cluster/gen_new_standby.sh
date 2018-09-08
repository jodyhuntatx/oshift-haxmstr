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
#  delete_failed_master $FAILED_MASTER
  new_standby_up $NEW_STANDBY
}

############################
delete_failed_master() {
  announce "Deleting failed master $FAILED_MASTER..."

  docker stop -f $FAILED_MASTER
  docker rm $FAILED_MASTER
  master_container_name=$(get_cluster_leader_name)
  docker exec $master_container_name evoke cluster member remove $FAILED_MASTER
}

############################
new_standby_up() {
  echo "Preparing standby seed files..."

  # update cluster policy with new node name
  docker cp ./cluster-policy.yml conjur-cli:/root/cluster-policy.yml
  docker exec -it conjur-cli conjur policy load --as-group security_admin cluster-policy.yml

  mkdir -p tmp
  master_container_name=$(get_cluster_leader_name)
  master_ip=$(docker inspect $master_container_name --format "{{ .NetworkSettings.IPAddress }}")
  docker exec $master_container_name evoke seed standby conjur-standby > ./tmp/standby-seed.tar

  start_standby $NEW_STANDBY
  configure_standby $NEW_STANDBY $master_ip
  docker exec -it $NEW_STANDBY evoke cluster enroll -n $NEW_STANDBY conjur-cluster

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

  docker network connect conjur-master-cluster $standby_name
}

############################
configure_standby() {
  local standby_name=$1; shift
  local master_ip=$1; shift

  printf "Configuring standby %s...\n" $standby_name

  docker cp ./tmp/standby-seed.tar $standby_name:/tmp/standby-seed.tar
    
  docker exec $standby_name evoke unpack seed /tmp/standby-seed.tar
  docker exec $standby_name evoke configure standby -i $master_ip 
#  -j /etc/conjur.json 

}

main $@
