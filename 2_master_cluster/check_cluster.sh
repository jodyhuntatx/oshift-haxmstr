#!/bin/bash
set -eou pipefail

. ../utils.sh

if [[ $# != 1 ]]; then
  echo "Usage: $0 <conjur-node-name>"
  exit -1
fi 
conjur_node=$1
echo
echo "##### node $conjur_node #####"
echo "== Node role: $(docker exec $conjur_node evoke role)"
echo "== Node status"
docker exec $conjur_node curl -sk http://localhost/health | jq .cluster
echo "== Cluster members"
docker exec -it $conjur_node evoke cluster member list
echo "== Cluster health"
docker exec -it $conjur_node etcdctl cluster-health
