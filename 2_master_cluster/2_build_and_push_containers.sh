#!/bin/bash 
set -eou pipefail

. ../utils.sh

oshift="${OSHIFT_CONJUR_ADMIN:-unset}"
if [[ $oshift != unset ]]; then
  oc login -u $OSHIFT_CONJUR_ADMIN
  set_project $CONJUR_PROJECT_NAME
  echo $(oc whoami -t) | docker login -u _ --password-stdin $DOCKER_REGISTRY_PATH
fi

main() {
  push_conjur_appliance
  push_haproxy
  push_cli
  echo "Docker images pushed."
}

####################
push_conjur_appliance() {
  announce "Building and pushing conjur-appliance image."

  if [[ $CONNECTED == true ]]; then
    pushd build/conjur_server
      ./build.sh
    popd
  else
    docker tag $CONJUR_APPLIANCE_IMAGE conjur-appliance:$CONJUR_PROJECT_NAME
  fi

  if [[ $oshift != unset ]]; then
    docker_tag_and_push $CONJUR_PROJECT_NAME "conjur-appliance"
  fi
}

####################
push_haproxy() {
  announce "Building and pushing haproxy image."

  if [[ $CONNECTED == true ]]; then
    pushd build/haproxy
      ./build.sh
    popd
  fi
}

####################
push_cli() {
  announce "Pulling and pushing Conjur CLI image."

  if [[ $CONNECTED == true ]]; then
    docker pull cyberark/conjur-cli:$CONJUR_VERSION-latest
  fi
  docker tag cyberark/conjur-cli:$CONJUR_VERSION-latest conjur-cli:$CONJUR_PROJECT_NAME

  if [[ $oshift != unset ]]; then
    docker_tag_and_push $CONJUR_PROJECT_NAME "conjur-cli"
  fi
}

main $@
