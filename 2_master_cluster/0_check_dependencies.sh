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
