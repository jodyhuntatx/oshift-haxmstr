#!/bin/bash
set -eou pipefail

. ../utils.sh

announce "Initializing Conjur certificate authority."

set_project $CONJUR_PROJECT_NAME

if [[ $NO_DNS == true ]]; then
  conjur_master=$(get_master_pod_name)
  docker exec -it $conjur_master conjur-plugin-service authn-k8s rake ca:initialize["conjur/authn-k8s/$AUTHENTICATOR_SERVICE_ID"]
else
  ssh -i $CONJUR_MASTER_SSH_KEY $CONJUR_MASTER_HOST_ADMIN@$CONJUR_MASTER_HOST_NAME docker exec conjur1 conjur-plugin-service authn-k8s rake ca:initialize["conjur/authn-k8s/$AUTHENTICATOR_SERVICE_ID"] 
fi

echo "Certificate authority initialized."

announce "Storing Conjur cert for test app configuration."

echo "Retrieving Conjur certificate."

follower_pod_name=$(oc get pods -l role=follower --no-headers | awk '{ print $1 }' | head -1)
ssl_cert=$(oc exec $follower_pod_name -- cat /opt/conjur/etc/ssl/conjur.pem)

set_project $TEST_APP_PROJECT_NAME

echo "Storing non-secret conjur cert as test app configuration data"

oc delete --ignore-not-found=true configmap $TEST_APP_PROJECT_NAME

# Store the Conjur cert in a ConfigMap.
oc create configmap $TEST_APP_PROJECT_NAME --from-file=ssl-certificate=<(echo "$ssl_cert")

echo "Conjur cert stored."
