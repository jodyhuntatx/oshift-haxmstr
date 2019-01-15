#!/bin/bash
set -eou pipefail

. ../utils.sh

announce "Initializing Conjur CA..."

if [[ $NO_DNS == true ]]; then
  conjur_master=$(get_master_pod_name)
  docker exec -it $conjur_master chpst -u conjur conjur-plugin-service possum rake authn_k8s:ca_init["conjur/authn-k8s/$AUTHENTICATOR_ID"]
else
  ssh -i $CONJUR_MASTER_SSH_KEY $CONJUR_MASTER_HOST_ADMIN@$CONJUR_MASTER_HOST_NAME docker exec -it $conjur_master chpst -u conjur conjur-plugin-service possum rake authn_k8s:ca_init["conjur/authn-k8s/$AUTHENTICATOR_ID"]
fi

echo "Certificate authority initialized."
