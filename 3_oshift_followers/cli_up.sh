############################
cli_up() {

  announce "Creating CLI container."

  start_cli
  configure_cli
}

############################
start_cli() {
  docker run -d \
    --name $CLI_CONTAINER_NAME \
    --label role=cli \
    --restart always \
    --security-opt seccomp:unconfined \
    --entrypoint sh \
    $CLI_IMAGE_NAME \
    -c "sleep infinity" 

  echo "CLI container launched."
}

############################
configure_cli() {

# DNS HACK - not needed if $CONJUR_MASTER_HOSTNAME resolves w/ DNS
# add entry to cli container's /etc/hosts so $CONJUR_MASTER_HOSTNAME resolves
#  CONJUR_MASTER_HOST_IP=$(ifconfig en0 | grep "inet " | awk '{print $2}')
#  docker exec -it $CLI_CONTAINER_NAME bash -c "echo \"$CONJUR_MASTER_HOST_IP    $CONJUR_MASTER_HOSTNAME\" >> /etc/hosts"

  wait_till_master_is_responsive
	# initialize cli for connection to master
  docker exec -it $CLI_CONTAINER_NAME bash -c "echo yes | conjur init -a $CONJUR_ACCOUNT -h $CONJUR_HOST --force=true"
        # configure policy plugin
  docker exec $CLI_CONTAINER_NAME sed -i.bak -e "s#\[\]#\[ policy \]#g" /root/.conjurrc
  docker exec $CLI_CONTAINER_NAME conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD

  echo "CLI container configured."
}

