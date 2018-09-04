#!/bin/bash -x
set -eou pipefail

. ../utils.sh

announce "Building and pushing test app images."

echo $(oc whoami -t) | docker login -u developer --password-stdin $DOCKER_REGISTRY_PATH

if [[ $CONNECTED == true ]]; then
  docker pull cyberark/conjur-kubernetes-authenticator
  pushd webapp
    ./build.sh
  popd
fi

docker tag cyberark/conjur-kubernetes-authenticator conjur-kubernetes-authenticator:$TEST_APP_PROJECT_NAME
docker_tag_and_push $TEST_APP_PROJECT_NAME conjur-kubernetes-authenticator

docker tag webapp:latest webapp:$TEST_APP_PROJECT_NAME
docker_tag_and_push $TEST_APP_PROJECT_NAME webapp
