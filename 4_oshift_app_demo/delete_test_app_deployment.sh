#!/bin/bash
set -eou pipefail

. ../utils.sh

announce "DESTROYING test apps."

set_project $TEST_APP_PROJECT_NAME

##############################
# Destroy web app.

oc delete -f manifests/${TEST_APP_PROJECT_NAME}-deploy.yaml --ignore-not-found=true

echo "Waiting for $TEST_APP_PROJECT_NAME pods to terminate..."
while [[ "$(oc get pods 2>&1)" != "No resources found." ]]; do
  echo -n '.'
  sleep 3
done
echo

echo "$TEST_APP_PROJECT_NAME app destroyed."

