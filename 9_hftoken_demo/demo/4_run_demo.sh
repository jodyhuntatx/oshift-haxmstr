#!/bin/bash
echo
echo "This script runs Summon which:"
echo "  - uses the files /etc/conjur.conf and /etc/conjur.identity "
echo "    to authenticate the host identity"
echo "  - retrieves the secrets specified in secrets.yml"
echo "  - calls echo_secrets which echos their values."
echo
echo "Contents of /etc/conjur.identity:"
echo
cat /etc/conjur.identity
summon ./echo_secrets.sh 
