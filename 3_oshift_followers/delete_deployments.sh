#!/bin/bash
#
# Destroys Conjur Openshift resources - all pods, services, routes, etc.
#
. ../utils.sh

set_project $CONJUR_PROJECT_NAME
oc login -u $OSHIFT_CONJUR_ADMIN

###################
# delete followers
sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" ./manifests/conjur-follower.yaml |
  sed -e "s#{{ AUTHENTICATOR_SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" |
  oc delete -f -

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
echo "Conjur followers deleted."