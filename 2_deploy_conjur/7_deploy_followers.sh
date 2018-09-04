#!/bin/bash  -x
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
  echo "Preparing follower seed files..."
  master_pod_name=$(get_master_pod_name)

  mkdir -p ./tmp
  docker exec $master_pod_name evoke seed follower conjur-follower > ./tmp/follower-seed.tar

  pod_list=$(oc get pods -l role=follower --no-headers | awk '{ print $1 }')
  for pod_name in $pod_list; do
    printf "Configuring follower %s...\n" $pod_name

    copy_file_to_container "./tmp/follower-seed.tar" "/tmp/follower-seed.tar" "$pod_name"

	# updating of hosts file can be removed if DNS resolves CONJUR_MASTER_HOSTNAME correctly
    oc exec -it $pod_name -- bash -c "echo \"$CONJUR_MASTER_HOST_IP    $CONJUR_MASTER_HOSTNAME\" >> /etc/hosts"
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

main $@
