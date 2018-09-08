#! /bin/bash 
set -eo pipefail

. ./bootstrap.env

CONJURIZE_CERT_FILE=/etc/conjur-dev.pem
CONJUR_ADMIN_UNAME=admin
CONJUR_ADMIN_PWD=Cyberark1
EXECUTOR_HF_NAME=jenkins/executor_factory
JOBS_HF_NAME=jenkins/jobs_factory
JOBS_HF_FILE=jobs_hf_token.txt
JENKINS_HOSTNAME=jenkins/master
HF_MINUTES=720

main() {
  echo "-----"
  init_conjur
  write_auth_env
  source auth.env
  /usr/local/bin/jenkins.sh &> /dev/null &
  echo "Waiting for Jenkins to start up..."
  sleep 15
#  setup_identity_files

  echo "Initial Jenkins admin password:" $(cat /var/jenkins_home/secrets/initialAdminPassword)
  echo "Environment variable to paste as CONJUR_APPLIANCE_URL:" $CONJUR_APPLIANCE_URL
  echo "Environment variable to paste as CONJUR_CERT_FILE:" $CONJUR_CERT_FILE
}

########################################
init_conjur() {
  rm -f ~/.conjurrc ~/conjur-dev.pem
  conjur init -h $CONJUR_HOST << END
yes
END
  conjur authn login -u $CONJUR_ADMIN_UNAME -p $CONJUR_ADMIN_PWD
  conjur policy load --as-group=security_admin policy.yml
  conjur variable values add secrets/test_db_username TestDBuserName
  conjur variable values add secrets/test_db_password $(openssl rand -hex 12)
  conjur variable values add secrets/prod_db_username ProdDBuserName
  conjur variable values add secrets/prod_db_password $(openssl rand -hex 12)
  JENKINS_HOST_API_KEY=$(conjur host rotate_api_key --host $JENKINS_HOSTNAME)
  JOBS_HF_TOKEN=$(conjur hostfactory tokens create --duration-minutes $HF_MINUTES $JOBS_HF_NAME | jq -r .[].token)
  echo $JOBS_HF_TOKEN > $JOBS_HF_FILE
}

####################
# in lieu of /etc/conjur* files being correctly read, write out authn info 
#
write_auth_env() {
	cat bootstrap.env > auth.env
	echo "#-------" >> auth.env
	echo "export CONJUR_AUTHN_LOGIN=host/$JENKINS_HOSTNAME" >> auth.env
	echo "export CONJUR_AUTHN_API_KEY=$JENKINS_HOST_API_KEY" >> auth.env
}

######################
# startup ansible container and copy over /etc/conjur* file content
#
setup_identity_files() {
				# conjurize: copy over conf
	cat <<CONF_EOF | sudo tee /etc/conjur.conf
---
appliance_url: $CONJUR_APPLIANCE_URL
account: $CONJUR_MASTER_ORGACCOUNT
cert_file: "$CONJUR_CERT_FILE_ON_HOST"
plugins: []
CONF_EOF
				# conjurize: copy over cert file
	cp $CONJUR_CERT_FILE $CONJURIZE_CERT_FILE


				# conjurize: copy over identity file
	cat <<IDENTITY_EOF | sudo tee /etc/conjur.identity
machine $CONJUR_APPLIANCE_URL/authn
login host/$JENKINS_HOSTNAME
password $JENKINS_HOST_API_KEY
IDENTITY_EOF
}

main "$@"
