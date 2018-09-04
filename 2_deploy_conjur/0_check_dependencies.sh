#!/bin/bash
set -eo pipefail

. ../utils.sh

oc login -u $OSHIFT_CLUSTER_ADMIN
set_project default

# Confirm logged into OpenShift.
if ! oc whoami 2 > /dev/null; then
  echo "You must login to OpenShift before running this demo."
  exit 1
fi

check_env_var "CONJUR_PROJECT_NAME"
check_env_var "CONJUR_APPLIANCE_IMAGE"
check_env_var "DOCKER_REGISTRY_PATH"
check_env_var "CONJUR_ACCOUNT"
check_env_var "CONJUR_ADMIN_PASSWORD"
check_env_var "AUTHENTICATOR_SERVICE_ID"

# Confirms Conjur image is present.
if [[ "$(docker images -q $CONJUR_APPLIANCE_IMAGE 2> /dev/null)" == "" ]]; then
  echo "You must have the Conjur v4 Appliance tagged as $CONJUR_APPLIANCE_IMAGE in your Docker engine to run this script."
  exit 1
fi
