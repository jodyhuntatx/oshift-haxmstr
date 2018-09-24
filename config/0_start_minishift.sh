#!/bin/bash -x
set -eou pipefail
if [[ "$OPENSHIFT_VERSION" == "" ]]; then
	echo "source config/minishift.config first before running this script."
	exit -1
fi
STARTUP=restart
if [[ $# == 1 ]]; then
  STARTUP=$1
fi
if [[ $STARTUP != restart ]]; then
  minishift delete -f
  rm -rf ~/.kube ~/.minishift
fi
minishift start --memory $MINISHIFT_VM_MEMORY --vm-driver virtualbox --show-libmachine-logs --openshift-version $OPENSHIFT_VERSION
echo ""
echo "IMPORTANT!  IMPORTANT!  IMPORTANT!  IMPORTANT!"
echo "You need to source config/conjur.config again to reference docker daemon in Minishift..."
echo ""
