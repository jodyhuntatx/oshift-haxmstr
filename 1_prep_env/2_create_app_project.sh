#!/bin/bash 
set -eou pipefail

oshift="${OSHIFT_CONJUR_ADMIN:-unset}"
if [[ $oshift == unset ]]; then
  echo "OpenShift Conjur project admin not set..."
  exit 0
fi

. ../utils.sh

oc login -u $OSHIFT_CLUSTER_ADMIN

if has_project "$TEST_APP_PROJECT_NAME"; then
  echo "Project '$TEST_APP_PROJECT_NAME' exists, not going to create it."
  set_project $TEST_APP_PROJECT_NAME
else
  echo "Creating '$TEST_APP_PROJECT_NAME' project."
  oc new-project $TEST_APP_PROJECT_NAME
  oc adm policy add-role-to-user admin $OSHIFT_CONJUR_ADMIN -n $TEST_APP_PROJECT_NAME
  oc adm policy add-scc-to-user anyuid -z $TEST_APP_PROJECT_NAME
fi

oc login -u $OSHIFT_CONJUR_ADMIN
set_project $TEST_APP_PROJECT_NAME

# Grant access to this project to Conjur authn-k8s service account 
oc delete --ignore-not-found rolebinding app-conjur-authenticator-role-binding

sed -e "s#{{ TEST_APP_PROJECT_NAME }}#$TEST_APP_PROJECT_NAME#g" ./manifests/app-conjur-authenticator-role-binding.yaml |
  sed -e "s#{{ CONJUR_PROJECT_NAME }}#$CONJUR_PROJECT_NAME#g" |
  oc create -f -

echo "$TEST_APP_PROJECT_NAME Project initialized."
