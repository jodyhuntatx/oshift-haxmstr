#!/bin/bash  -x
# fake DNS IP resolution with /etc/hosts entry
echo "$CONJUR_MASTER_HOST_IP   $CONJUR_MASTER_HOST_NAME" >> /etc/hosts

APP_HOSTNAME=webapp/tomcat_host

# delete old identity stuff
rm -f /root/.conjurrc /root/conjur*.pem

# initialize client environment
conjur init -u https://$CONJUR_MASTER_HOST_NAME:$CONJUR_MASTER_PORT -a $CONJUR_ACCOUNT --force=true

sleep 2
conjur authn login -u admin -p Cyberark1
conjur policy load root webapp-identity.yml
conjur policy load root webapp-secrets.yml
conjur variable values add webapp-secrets/database_username DatabaseUser
conjur variable values add webapp-secrets/database_password $(openssl rand -hex 12)

# create configuration and identity files (AKA conjurization)
cp ~/conjur-$CONJUR_ACCOUNT.pem /etc

				# generate api key
api_key=$(conjur host rotate_api_key --host $APP_HOSTNAME)

				# copy over identity file
echo "Generating identity file..."
cat <<IDENTITY_EOF | tee /etc/conjur.identity
machine $CONJUR_APPLIANCE_URL/authn
  login host/$APP_HOSTNAME
  password $api_key
IDENTITY_EOF

echo
echo "Generating host configuration file..."
cat <<CONF_EOF | tee /etc/conjur.conf
---
appliance_url: $CONJUR_APPLIANCE_URL
account: $CONJUR_ACCOUNT
netrc_path: "/etc/conjur.identity"
cert_file: "/etc/conjur-$CONJUR_ACCOUNT.pem"
CONF_EOF

chmod go-rw /etc/conjur.identity

# delete user identity files to force use of /etc/conjur* host identity files.
rm ~/.conjurrc ~/.netrc
