#!/bin/bash 
. ../utils.sh
app_pod_name=$(oc get pods | grep $TEST_APP_PROJECT_NAME | awk '{ print $1 }')
oc exec -it $app_pod_name -- bash
