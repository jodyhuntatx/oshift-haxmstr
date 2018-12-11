#!/bin/bash 
set -euo pipefail

. ../utils.sh

oc project $TEST_APP_PROJECT_NAME

clear
announce "Retrieving secrets using Conjur access token."

app_pod=$(oc get pods --ignore-not-found --no-headers -l app=$TEST_APP_PROJECT_NAME | awk '{ print $1 }')
if [[ "$app_pod" != "" ]]; then
  echo "App using secrets retrieved with REST API:"
  oc exec -c $TEST_APP_PROJECT_NAME $app_pod -- /webapp_v$CONJUR_VERSION.sh
  echo "App using secrets retrieved with Summon:"
  oc exec -c $TEST_APP_PROJECT_NAME $app_pod -- summon /webapp_summon.sh
fi
echo
