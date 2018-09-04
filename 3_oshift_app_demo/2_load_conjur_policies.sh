#!/bin/bash 
set -eou pipefail

. ../utils.sh

announce "Loading Conjur policy."

sed -e "s#{{ AUTHENTICATOR_SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" \
     ./policy/templates/cluster-authn-defs.template.yml \
   > ./policy/generated/cluster-authn-defs.yml

sed -e "s#{{ AUTHENTICATOR_SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" \
    ./policy/templates/project-authn-defs.template.yml |
  sed -e "s#{{ TEST_APP_PROJECT_NAME }}#$TEST_APP_PROJECT_NAME#g" \
  > ./policy/generated/project-authn-defs.yml

sed -e "s#{{ AUTHENTICATOR_SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" \
    ./policy/templates/app-identity-defs.template.yml |
  sed -e "s#{{ TEST_APP_PROJECT_NAME }}#$TEST_APP_PROJECT_NAME#g" \
  > ./policy/generated/app-identity-defs.yml

sed -e "s#{{ AUTHENTICATOR_SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" \
    ./policy/templates/resource-access-grants.template.yml |
  sed -e "s#{{ TEST_APP_PROJECT_NAME }}#$TEST_APP_PROJECT_NAME#g" \
  > ./policy/generated/resource-access-grants.yml

set_project $CONJUR_PROJECT_NAME

# copy policy directory contents to cli
docker cp ./policy conjur-cli:/

docker exec -it conjur-cli conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD

POLICY_FILE_LIST="
policy/users/users.yml
policy/generated/project-authn-defs.yml
policy/generated/cluster-authn-defs.yml
policy/generated/app-identity-defs.yml
policy/generated/resource-access-grants.yml
"
for i in $POLICY_FILE_LIST; do
	echo "Loading policy file: $i"
	docker exec conjur-cli conjur policy load --as-group security_admin "/$i"
done

docker exec conjur-cli conjur variable values add secrets/db-password $(openssl rand -hex 12)

echo "Conjur policy loaded."
