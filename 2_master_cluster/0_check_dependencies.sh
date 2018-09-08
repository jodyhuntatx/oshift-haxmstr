#!/bin/bash
set -eo pipefail

. ../utils.sh

check_env_var "CONJUR_VERSION"
check_env_var "CONJUR_ACCOUNT"
check_env_var "CONJUR_MASTER_HOST_IP"
check_env_var "CONJUR_MASTER_PORT"
check_env_var "CONJUR_MASTER_PGSYNC_PORT"
check_env_var "CONJUR_MASTER_PGAUDIT_PORT"
check_env_var "CONJUR_MASTER_HOST"
check_env_var "CONJUR_MASTER_CONTAINER_NAME"
check_env_var "CLI_CONTAINER_NAME"
check_env_var "CLI_IMAGE_NAME"

# Confirms Conjur image is present.
if [[ "$(docker images -q $CONJUR_APPLIANCE_IMAGE 2> /dev/null)" == "" ]]; then
  echo "You must have the Conjur v4 Appliance tagged as $CONJUR_APPLIANCE_IMAGE in your Docker engine to run this script."
  exit 1
fi
