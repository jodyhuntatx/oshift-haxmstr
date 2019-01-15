#!/bin/bash
if [[ "$KUBERNETES_VERSION" == "" ]]; then
	echo "source kubernetes.config first before running this script."
	exit -1
fi
# if no existing VM, delete past login state and minikube resources 
if [[ "$(minikube status | grep minikube | awk '{print $2}')" == "" ]]; then
  minikube delete
  rm -rf $KUBECONFIG ~/.minikube
fi
minikube config set memory $MINIKUBE_VM_MEMORY
minikube start --memory $MINIKUBE_VM_MEMORY --vm-driver virtualbox --kubernetes-version $KUBERNETES_VERSION 
#remove all taints from the minikube node so that pods will get scheduled
sleep 5
kubectl patch node minikube -p '{"spec":{"taints":[]}}'

# delete Exited containers
docker rm $(docker container ls -a | grep Exited | awk '{print $1}')

echo ""
echo "IMPORTANT!  IMPORTANT!  IMPORTANT!  IMPORTANT!"
echo "You need to source kuberenetes.config again to reference docker daemon in Minikube..."
echo ""
