#!/bin/bash 
set -eou pipefail

. ../utils.sh

oc login -u $OSHIFT_CONJUR_ADMIN
set_project $CONJUR_PROJECT_NAME

main() {
  deploy_follower_pods
  sleep 5
  configure_followers
}

#######################
deploy_follower_pods() {
  announce "Deploying follower pods..."

  oc login -u $OSHIFT_CLUSTER_ADMIN
  oc adm policy add-scc-to-user anyuid -z default
  oc adm policy add-scc-to-user anyuid -z $CONJUR_PROJECT_NAME
  oc login -u $OSHIFT_CONJUR_ADMIN

  conjur_appliance_image=$DOCKER_REGISTRY_PATH/$CONJUR_PROJECT_NAME/conjur-appliance:$CONJUR_PROJECT_NAME
  sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" ./manifests/conjur-follower.yaml |
    sed -e "s#{{ AUTHENTICATOR_SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" |
    oc create -f -
}

#######################
configure_followers() {
  announce "Configuring followers."

  mkdir -p ./tmp
  get_seed_file_from_master ./tmp

  pod_list=$(oc get pods -l role=follower --no-headers | awk '{ print $1 }')
  for pod_name in $pod_list; do
    printf "Configuring follower %s...\n" $pod_name

    copy_file_to_container "./tmp/follower-seed.tar" "/tmp/follower-seed.tar" "$pod_name"

	# updating of hosts file can be removed if DNS resolves CONJUR_MASTER_HOST_NAME correctly
    if [[ $NO_DNS == true ]]; then
      oc exec -it $pod_name -- bash -c "echo \"$CONJUR_MASTER_HOST_IP    $CONJUR_MASTER_HOST_NAME\" >> /etc/hosts"
    fi
    oc exec -it $pod_name -- evoke unpack seed /tmp/follower-seed.tar
    oc exec -it $pod_name -- evoke configure follower -p $CONJUR_MASTER_PORT
  done

  oc login -u $OSHIFT_CLUSTER_ADMIN
  oc adm policy remove-scc-from-user anyuid -z default
  oc adm policy remove-scc-from-user anyuid -z $CONJUR_PROJECT_NAME
  oc login -u $OSHIFT_CONJUR_ADMIN

  rm -rf tmp
  echo "Followers configured."
}

############################
get_seed_file_from_master() {
  local temp_dir=$1; shift

  echo "Retrieving follower seed file..."
  if [[ $NO_DNS = true ]]; then
    cp ../etc/follower-seed.tar $temp_dir
  else
    scp -i $CONJUR_MASTER_SSH_KEY $CONJUR_MASTER_HOST_ADMIN@$CONJUR_MASTER_HOST_IP:~/follower-seed.tar $temp_dir
  fi
}

main $@
