#!/bin/bash 
containers="conjur1 conjur2 conjur3"

get_master_name() {
  for i in $containers; do
    if [[ $(docker exec $i curl -sk http://localhost/health \
                                 | jq -Mr .cluster.ok) == "true" ]]; then
      if [[ $(docker exec $i evoke role) == master ]]; then
        echo -n $i
        exit 0
      fi
    fi
  done
}

get_cluster_leader_name() {
  for i in $containers; do
    leader_name=$(docker exec -it $i etcdctl member list | grep isLeader=true | awk '{ print $2 }' | cut -d = -f 2)
    if [[ "$leader_name" != "" ]]; then
      echo -n $leader_name
      exit 0
    fi
  done
}

get_cluster_follower_names() {
  for i in $containers; do
    followers=$(docker exec -it $i etcdctl member list | grep isLeader=false | awk '{ print $2 }' | cut -d = -f 2)
  done
  echo $followers
}

echo "Master is: $(get_master_name)"
echo "Cluster leader is: $(get_cluster_leader_name)"
echo "Cluster follower(s) is/are: $(get_cluster_follower_names)"
