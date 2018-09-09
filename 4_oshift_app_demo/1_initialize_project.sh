#!/bin/bash -x
set -eou pipefail

. ../utils.sh

oc login -u $OSHIFT_CLUSTER_ADMIN

if has_project "$TEST_APP_PROJECT_NAME"; then
  echo "Project '$TEST_APP_PROJECT_NAME' exists, not going to create it."
  set_project $TEST_APP_PROJECT_NAME
else
  echo "Creating '$TEST_APP_PROJECT_NAME' project."
  oc new-project $TEST_APP_PROJECT_NAME
  oc adm policy add-role-to-user admin developer -n $TEST_APP_PROJECT_NAME
  oc adm policy add-scc-to-user anyuid -z $TEST_APP_PROJECT_NAME
fi

oc login -u $OSHIFT_CONJUR_ADMIN
set_project $TEST_APP_PROJECT_NAME

oc delete --ignore-not-found rolebinding app-conjur-authenticator-role-binding

sed -e "s#{{ TEST_APP_PROJECT_NAME }}#$TEST_APP_PROJECT_NAME#g" ./manifests/app-conjur-authenticator-role-binding.yaml |
  sed -e "s#{{ CONJUR_PROJECT_NAME }}#$CONJUR_PROJECT_NAME#g" |
  oc create -f -

echo "Project initialized."
