#!/bin/bash -x
docker cp synch_policy.yml conjur-cli:/synch_policy.yml
docker exec -it conjur-cli conjur policy load root synch_policy.yml
