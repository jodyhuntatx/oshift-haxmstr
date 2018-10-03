#!/bin/bash 
set -eou pipefail

. ../utils.sh

announce "Deploying test apps."

set_project $TEST_APP_PROJECT_NAME

oc delete --ignore-not-found secrets dockerpullsecret

# Set credentials for Docker registry.
oc secrets new-dockercfg dockerpullsecret \
   --docker-server=${DOCKER_REGISTRY_PATH} --docker-username=_ \
   --docker-password=$(oc whoami -t) --docker-email=_
oc secrets add serviceaccount/default secrets/dockerpullsecret --for=pull

# Delete old deployments.
oc delete --ignore-not-found deploymentconfigs $TEST_APP_PROJECT_NAME

sleep 5

# Deploy web app.
webapp_docker_image=$DOCKER_REGISTRY_PATH/$TEST_APP_PROJECT_NAME/webapp:$TEST_APP_PROJECT_NAME
authn_docker_image=$DOCKER_REGISTRY_PATH/$TEST_APP_PROJECT_NAME/conjur-kubernetes-authenticator:$TEST_APP_PROJECT_NAME

sed -e "s#{{ TEST_APP_DOCKER_IMAGE }}#$webapp_docker_image#g" ./manifests/deploy-template.yaml |
  sed -e "s#{{ AUTHN_DOCKER_IMAGE }}#$authn_docker_image#g" |
  sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#g" |
  sed -e "s#{{ CONJUR_VERSION }}#$CONJUR_VERSION#g" |
  sed -e "s#{{ CONJUR_PROJECT_NAME }}#$CONJUR_PROJECT_NAME#g" |
  sed -e "s#{{ TEST_APP_PROJECT_NAME }}#$TEST_APP_PROJECT_NAME#g" |
  sed -e "s#{{ SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" |
  sed -e "s#{{ CONFIG_MAP_NAME }}#$TEST_APP_PROJECT_NAME#g" > ./manifests/${TEST_APP_PROJECT_NAME}-deploy.yaml

oc create -f ./manifests/${TEST_APP_PROJECT_NAME}-deploy.yaml

echo "Waiting for application pod to initialize..."

sleep 8

echo "Test app deployed."
