#!/bin/bash
set -eo pipefail

. ../utils.sh

check_env_var "OSHIFT_CLUSTER_ADMIN"
check_env_var "OSHIFT_CONJUR_ADMIN"
check_env_var "CONJUR_PROJECT_NAME"
check_env_var "CONJUR_APPLIANCE_IMAGE"
check_env_var "CONJUR_MASTER_HOST_NAME"
check_env_var "CONJUR_MASTER_HOST_IP"
check_env_var "CONJUR_MASTER_HOST"
check_env_var "CONJUR_MASTER_PORT"
check_env_var "CLI_CONTAINER_NAME"
check_env_var "CLI_IMAGE_NAME"
check_env_var "DOCKER_REGISTRY_PATH"
check_env_var "CONJUR_ACCOUNT"
check_env_var "CONJUR_ADMIN_PASSWORD"
check_env_var "AUTHENTICATOR_SERVICE_ID"
if [[ "$NO_DNS" == "false" ]]; then
  check_env_var "CONJUR_MASTER_SSH_KEY"
fi

# Confirms Conjur image is present.
if [[ "$(docker images -q $CONJUR_APPLIANCE_IMAGE 2> /dev/null)" == "" ]]; then
  echo "You must have the Conjur v4 Appliance tagged as $CONJUR_APPLIANCE_IMAGE in your Docker engine to run this script."
  exit 1
fi

oc login -u $OSHIFT_CLUSTER_ADMIN
set_project default

# Confirm logged into OpenShift.
if ! oc whoami 2 > /dev/null; then
  echo "You must login to OpenShift before running this demo."
  exit 1
fi

