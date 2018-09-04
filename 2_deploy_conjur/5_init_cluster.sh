#!/bin/bash 
set -eou pipefail

. ../utils.sh

oc login -u $OSHIFT_CONJUR_ADMIN
set_project $CONJUR_PROJECT_NAME

main() {
  docker cp ./cluster-policy.yml conjur-cli:/root/cluster-policy.yml
  docker exec -it conjur-cli conjur policy load --as-group security_admin cluster-policy.yml
  docker exec -it $CONJUR_MASTER_CONTAINER_NAME evoke cluster enroll -n $CONJUR_MASTER_CONTAINER_NAME conjur-cluster
}

main $@
