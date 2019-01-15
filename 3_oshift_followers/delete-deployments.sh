#!/bin/bash 
#set -eo pipefail

. utils.sh

announce "Deleting Conjur Followers."

set_namespace $CONJUR_NAMESPACE_NAME

conjur_appliance_image=$(platform_image "conjur-appliance")

if is_minienv; then
  IMAGE_PULL_POLICY='Never'
else
  IMAGE_PULL_POLICY='Always'
fi

announce "Deleting Follower pods."
sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" "./$PLATFORM/conjur-follower.yaml" |
  sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
  sed -e "s#{{ CONJUR_FOLLOWER_COUNT }}#$CONJUR_FOLLOWER_COUNT#g" |
  sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
  $cli delete --ignore-not-found -f -

if [ $PLATFORM == openshift ]; then
  $cli delete --ignore-not-found deploymentconfig conjur-cluster
fi

echo "Waiting for Conjur pods to terminate..."
while [[ "$($cli get pods 2>&1)" != "No resources found." ]]; do
  echo -n '.'
  sleep 3
done 
echo

echo "Followers deleted."
