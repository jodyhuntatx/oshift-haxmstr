#!/bin/bash
set -eo pipefail

. ../utils.sh

check_env_var "DOCKER_REGISTRY_PATH"
check_env_var "CONJUR_ACCOUNT"
check_env_var "CONJUR_VERSION"
check_env_var "CONJUR_MASTER_HOST_NAME"
if [[ $NO_DNS == false ]]; then
  check_env_var "CONJUR_MASTER_HOST_ADMIN"
  check_env_var "CONJUR_MASTER_SSH_KEY"
fi
check_env_var "CONJUR_MASTER_HOST_IP"
check_env_var "CONJUR_ADMIN_PASSWORD"
check_env_var "AUTHENTICATOR_SERVICE_ID"
check_env_var "OSHIFT_CONJUR_ADMIN"
check_env_var "CONJUR_PROJECT_NAME"
check_env_var "TEST_APP_PROJECT_NAME"

# Confirm logged into OpenShift.
if ! oc whoami 2 > /dev/null; then
  echo "You must login to OpenShift before running this demo."
  exit 1
fi

