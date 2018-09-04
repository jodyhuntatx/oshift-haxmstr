#!/bin/bash
#
# Destroys Conjur cluster - all pods, services, routes, etc.
#
. ../utils.sh

set_project $CONJUR_PROJECT_NAME
oc login -u $OSHIFT_CONJUR_ADMIN

###################
# delete followers
sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" ./manifests/conjur-follower.yaml |
  sed -e "s#{{ AUTHENTICATOR_SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" |
  oc delete -f -

exit

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

###################
# delete imagestreams (only do if rebuilding images - must re-push)
#oc delete imagestream conjur-appliance
#oc delete imagestream conjur-cli

echo "Waiting for Conjur pods to terminate..."
while [[ "$(oc get pods 2>&1)" != "No resources found." ]]; do
  echo -n '.'
  sleep 3
done 

echo
echo "Conjur cluster deleted."
