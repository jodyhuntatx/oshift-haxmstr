#!/bin/bash 
set -eou pipefail

. ../utils.sh

oc login -u $OSHIFT_CONJUR_ADMIN
set_project $CONJUR_PROJECT_NAME

main() {
  push_conjur_appliance
  tag_cli
  echo "Docker images pushed."
}

####################
push_conjur_appliance() {
  announce "Building and pushing conjur-appliance image."

  echo $(oc whoami -t) | docker login -u _ --password-stdin $DOCKER_REGISTRY_PATH

  if [[ $CONNECTED == true ]]; then
    pushd build/conjur_server
      ./build.sh
    popd
  else
    docker tag $CONJUR_APPLIANCE_IMAGE conjur-appliance:$CONJUR_PROJECT_NAME
  fi

  docker_tag_and_push $CONJUR_PROJECT_NAME "conjur-appliance"
}

####################
tag_cli() {
  announce "Pulling Conjur CLI image."

  if [[ $CONNECTED == true ]]; then
    docker pull $CONJUR_CLI_IMAGE
  fi
}

main $@
