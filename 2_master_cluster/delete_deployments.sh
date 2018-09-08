#!/bin/bash
#
# Destroys Conjur master cluster
#
. ../utils.sh

###################
# delete master cluster
docker stop conjur-master; docker rm conjur-master
docker stop conjur3; docker rm conjur3
docker stop conjur2; docker rm conjur2
docker stop conjur1; docker rm conjur1
docker network rm conjur-master-cluster

###################
# delete cli
docker stop conjur-cli; docker rm conjur-cli

echo
echo "Conjur cluster deleted."
