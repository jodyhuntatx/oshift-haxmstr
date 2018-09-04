#!/bin/bash -x
set -eou pipefail

. ../utils.sh

oc login -u $OSHIFT_CONJUR_ADMIN
set_project $CONJUR_PROJECT_NAME

CLI_CONTAINER_NAME=conjur-cli
CLI_IMAGE_NAME=cyberark/conjur-cli:4-latest
CONJUR_HOST=$CONJUR_MASTER_HOSTNAME:$CONJUR_MASTER_PORT

  announce "Creating CLI container."

  docker run -d \
    --name $CLI_CONTAINER_NAME \
    --label role=cli \
    --restart always \
    --security-opt seccomp:unconfined \
    --entrypoint sh \
    $CLI_IMAGE_NAME \
    -c "sleep infinity" 

  echo "CLI container launched."

	# add entry to cli container's /etc/hosts so conjur-master resolves
  docker exec -it $CLI_CONTAINER_NAME bash -c "echo \"$CONJUR_MASTER_HOST_IP    $CONJUR_MASTER_HOSTNAME\" >> /etc/hosts"

        # wait until master is reachable
  master_is_healthy=""
  while [[ "$master_is_healthy" != "" ]]; do
    sleep 2
    master_is_healthy=$(docker exec -it conjur-cli curl -k https://$CONJUR_HOST/health | grep "ok" | tail -1 | grep "true")
  done

	# initialize cli for connection to master
  docker exec -it $CLI_CONTAINER_NAME bash -c "echo yes | conjur init -a $CONJUR_ACCOUNT -h $CONJUR_HOST --force=true"
        # configure policy plugin
  docker exec $CLI_CONTAINER_NAME sed -i.bak -e "s#\[\]#\[ policy \]#g" /root/.conjurrc
  docker exec $CLI_CONTAINER_NAME conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD

echo "CLI container created."
