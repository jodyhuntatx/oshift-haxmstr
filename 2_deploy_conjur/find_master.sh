#!/bin/bash 
. ../utils.sh
echo "Master is: $(get_master_pod_name)"
echo "Cluster leader is: $(get_cluster_leader_name)"

