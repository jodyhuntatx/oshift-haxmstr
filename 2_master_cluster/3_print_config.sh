#!/bin/bash 
set -eou pipefail

. ../utils.sh

announce "
Conjur cluster is ready.

Addresses for the Conjur Master service:

    Hostname: $CONJUR_MASTER_HOST_NAME
    IP address: $CONJUR_MASTER_HOST_IP
    Port: $CONJUR_MASTER_PORT

Conjur login credentials:
  admin / $CONJUR_ADMIN_PASSWORD
"
