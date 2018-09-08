#!/bin/bash
if [[ $# != 2 ]]; then
  echo "Usage: $0 <current-master> <seconds-to-pause>"
  exit -1
fi
docker pause $1
sleep $2
docker unpause $1
./check_cluster.sh $1
