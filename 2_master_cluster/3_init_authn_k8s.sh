#!/bin/bash
set -eou pipefail

. ../utils.sh

announce "Initializing Conjur authentication resources."

set_project $CONJUR_PROJECT_NAME

sed -e "s#{{ AUTHENTICATOR_SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" \
    ./policy/templates/project-authn-defs.template.yml |
  sed -e "s#{{ TEST_APP_PROJECT_NAME }}#$TEST_APP_PROJECT_NAME#g" \
  > ./policy/project-authn-defs.yml

sed -e "s#{{ AUTHENTICATOR_SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" \
     ./policy/templates/cluster-authn-defs.template.yml \
   > ./policy/cluster-authn-defs.yml

sed -e "s#{{ AUTHENTICATOR_SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" \
    ./policy/templates/app-identity-defs.template.yml |
  sed -e "s#{{ TEST_APP_PROJECT_NAME }}#$TEST_APP_PROJECT_NAME#g" \
  > ./policy/app-identity-defs.yml

sed -e "s#{{ AUTHENTICATOR_SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" \
    ./policy/templates/resource-access-grants.template.yml |
  sed -e "s#{{ TEST_APP_PROJECT_NAME }}#$TEST_APP_PROJECT_NAME#g" \
  > ./policy/resource-access-grants.yml

# copy policy directory contents to cli
docker cp ./policy conjur-cli:/

docker exec -it conjur-cli conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD

POLICY_FILE_LIST="
policy/project-authn-defs.yml
policy/cluster-authn-defs.yml
policy/app-identity-defs.yml
policy/resource-access-grants.yml
"
for i in $POLICY_FILE_LIST; do
        echo "Loading policy file: $i"
        docker exec conjur-cli conjur policy load root "/$i"
done

# create initial value for db-password variable
docker exec conjur-cli conjur variable values add secrets/db-password $(openssl rand -hex 12)

if [[ $NO_DNS == true ]]; then
  conjur_master=$(get_master_pod_name)
  docker exec -it $conjur_master chpst -u conjur conjur-plugin-service possum rake authn_k8s:ca_init["conjur/authn-k8s/$AUTHENTICATOR_SERVICE_ID"]
else
  ssh -i $CONJUR_MASTER_SSH_KEY $CONJUR_MASTER_HOST_ADMIN@$CONJUR_MASTER_HOST_NAME docker exec -it $conjur_master chpst -u conjur conjur-plugin-service possum rake authn_k8s:ca_init["conjur/authn-k8s/$AUTHENTICATOR_SERVICE_ID"]
fi

echo "Certificate authority initialized."
