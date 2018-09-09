#!/bin/bash
set -eou pipefail

oshift="${OSHIFT_CONJUR_ADMIN:-unset}"
if [[ $oshift == unset ]]; then
  exit 0
fi

. ../utils.sh

announce "Creating Conjur project."

oc login -u $OSHIFT_CLUSTER_ADMIN
set_project default

if has_project "$CONJUR_PROJECT_NAME"; then
  echo "Project '$CONJUR_PROJECT_NAME' exists, not going to create it."
  set_project $CONJUR_PROJECT_NAME
else
  echo "Creating '$CONJUR_PROJECT_NAME' project."
  oc new-project $CONJUR_PROJECT_NAME
fi

set_project $CONJUR_PROJECT_NAME

oc adm policy add-role-to-user admin $OSHIFT_CONJUR_ADMIN -n $CONJUR_PROJECT_NAME
oc adm policy add-role-to-user system:registry $OSHIFT_CONJUR_ADMIN
oc adm policy add-role-to-user system:image-builder $OSHIFT_CONJUR_ADMIN
