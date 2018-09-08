#!/bin/bash
. ./bootstrap.env
rm -f ~/.conjurrc ~/conjur-dev.pem
conjur init -h $CONJUR_HOST << END
yes
END
conjur authn login -u admin -p Cyberark1
conjur policy load --as-group security_admin synch_policy.yml
