#!/bin/bash 

. ./bootstrap.env

export JENKINS_JOB_NAME=2_ExternalSummonDemo
export CONJUR_AUTHN_LOGIN=host/$JENKINS_JOB_NAME
HF_TOKEN_FILE=jobs_hf_token.txt

if [ $# -ne 1 ]; then
	printf "Specify an environment: dev, test or prod\n\n"
	exit -1
fi

ENV=$1
if [[ ! -f $HF_TOKEN_FILE ]]; then
	printf "Host factory token file for jobs does not exist.\n\n"
	exit -1
fi
read HF_TOKEN < $HF_TOKEN_FILE
HF_NAME=jenkins/jobs_factory
export CONJUR_AUTHN_API_KEY=$(conjur hostfactory hosts create $HF_TOKEN $JENKINS_JOB_NAME | jq -r .api_key)
set -x
summon -e $1 bash -c "curl -s -X POST -u admin:Cyberark1 http://localhost:8080/job/$JENKINS_JOB_NAME/buildWithParameters?token=xyz\&DB_UNAME=\$DB_UNAME\&DB_PWD=\$DB_PWD"
