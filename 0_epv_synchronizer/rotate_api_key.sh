#!/bin/bash
docker exec conjur-cli conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD
SYNC_HOST=$(docker exec conjur-cli conjur list | grep Sync_ | cut -f 3 -d :| sed s/[^a-zA-Z0-9.-]//g)
docker exec conjur-cli conjur host rotate_api_key -h $SYNC_HOST
