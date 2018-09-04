#!/bin/bash

. ../utils.sh

set_project $CONJUR_PROJECT_NAME

oc delete imagestream conjur-follower-intlzd
FOLLOWER_CONTAINER_ID=$(docker ps | grep follower | grep conjur-appliance | awk '{ print $1 }')
docker commit -m "Pre-configured Conjur Follower" $FOLLOWER_CONTAINER_ID conjur-follower-intlzd:$CONJUR_PROJECT_NAME
docker_tag_and_push $CONJUR_PROJECT_NAME "conjur-follower-intlzd"
