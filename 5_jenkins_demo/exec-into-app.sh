#!/bin/bash
if [[ "$DOCKER_HOST" != "" ]]; then
  # use localhost docker daemon for docker-compose support
  unset DOCKER_TLS_VERIFY
  unset DOCKER_HOST
  unset DOCKER_CERT_PATH
fi
docker exec -it -u root jenkins-master bash
