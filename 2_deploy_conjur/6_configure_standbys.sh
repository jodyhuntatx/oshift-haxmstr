#!/bin/bash
set -eou pipefail

. ../utils.sh

oc login -u $OSHIFT_CONJUR_ADMIN
set_project $CONJUR_PROJECT_NAME

############################
main() {

  announce "Configuring standbys."

  echo "Preparing standby seed files..."

  mkdir -p tmp
  master_container_name=$(get_master_pod_name)
  master_ip=$(docker inspect $master_container_name --format "{{ .NetworkSettings.IPAddress }}")
  docker exec $master_container_name evoke seed standby conjur-node > ./tmp/standby-seed.tar
  
  configure_standby conjur2 $master_ip
  configure_standby conjur3 $master_ip

  rm -rf tmp

  echo "Starting synchronous replication..."

  docker exec $master_container_name evoke replication sync

  echo "Standbys configured."
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

  docker exec -it $standby_name evoke cluster enroll -n $standby_name conjur-cluster
}

main $@
