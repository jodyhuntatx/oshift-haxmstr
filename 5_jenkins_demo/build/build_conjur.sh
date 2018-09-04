#!/bin/bash
CONJUR_APPLIANCE_TAR=~/conjur-install-images/conjur-appliance-4.9.16.0.tar
CONJUR_SOURCE_IMAGE=conjur-appliance:latest
CONJUR_COMMIT_IMAGE=conjur-appliance:intlzd
CONJUR_MASTER_NAME=conjur_master
CONJUR_BUILD_CONTAINER_NAME=conjur-master
PASSWORD=Cyberark1
ORG=dev

docker run -d --restart always \
		--security-opt seccomp:unconfined \
		--name $CONJUR_BUILD_CONTAINER_NAME \
		-p "443:443" -p "636:636" -p "5432:5432" -p "5433:5433" \
		$CONJUR_SOURCE_IMAGE
docker exec $CONJUR_BUILD_CONTAINER_NAME evoke configure master -h $CONJUR_MASTER_NAME -p $PASSWORD $ORG

docker commit -a "Jody Hunt @ CyberArk jody.hunt@cyberark.com" \
		-m "This is a pre-configured Conjur Master node" \
		$CONJUR_BUILD_CONTAINER_NAME \
		$CONJUR_COMMIT_IMAGE
docker stop $CONJUR_BUILD_CONTAINER_NAME
docker rm $CONJUR_BUILD_CONTAINER_NAME
