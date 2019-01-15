#!/bin/bash -e

# For minishift deployments
# use "minishift openshift version list" to see supported versions
# use: "minishift openshift version" to see installed version
# visit: https://github.com/openshift/origin/tags
# to see versions with downloadable artifacts (e.g. images)
export OPENSHIFT_VERSION="v3.9.0"
export MINISHIFT_VM_MEMORY="6144"

if [[ "$1" == "reinstall" ]]; then
  minishift delete -f || true
  rm -rf $KUBECONFIG ~/.minishift
fi

if [[ "$(minishift status | grep Running)" != "" ]]; then
  echo "Your minishift environment is already up - skipping creation!"
else
  minishift start --memory "$MINISHIFT_VM_MEMORY" \
                  --vm-driver virtualbox \
                  --show-libmachine-logs \
                  --openshift-version "$OPENSHIFT_VERSION"
fi
eval $(minishift docker-env)
docker rm $(docker container ls -a | grep Exited | awk '{print $1}')

echo ""
echo "IMPORTANT!  IMPORTANT!  IMPORTANT!  IMPORTANT!"
echo "You need to source ../demo.config again to reference docker daemon in Minishift..."
echo ""
