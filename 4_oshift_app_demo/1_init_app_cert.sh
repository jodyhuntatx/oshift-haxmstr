#!/bin/bash
set -eou pipefail

. ../utils.sh

announce "Storing Conjur cert for app configuration."

echo "Retrieving Conjur certificate."

set_project $CONJUR_PROJECT_NAME

follower_pod_name=$(oc get pods -l role=follower --no-headers | awk '{ print $1 }' | head -1)
ssl_cert=$(oc exec $follower_pod_name -- cat /opt/conjur/etc/ssl/conjur.pem)

set_project $TEST_APP_PROJECT_NAME

echo "Storing non-secret conjur cert as test app configuration data"

oc delete --ignore-not-found=true configmap $TEST_APP_PROJECT_NAME

# Store the Conjur cert in a ConfigMap.
oc create configmap $TEST_APP_PROJECT_NAME --from-file=ssl-certificate=<(echo "$ssl_cert")

echo "Conjur cert stored."
