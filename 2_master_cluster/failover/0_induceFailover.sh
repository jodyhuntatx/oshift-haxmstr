#!/bin/bash
set -eou pipefail
if [[ "$#" != 1 ]]; then
  echo "Specify number of seconds to pause current master..."
  exit -1
fi

pause_secs=$1

main() {
  find_master
  echo_version
  echo "Pausing" $current_master "for" $pause_secs "seconds..."
  timestamp
  docker pause $current_master > /dev/null
  sleep $pause_secs
  timestamp
  docker unpause $current_master > /dev/null
}

find_master() {
  cont_list=$(docker ps -f "label=role=conjur_node" --format "{{ .Names }}")
  for i in $cont_list; do
    if [[ $(docker exec $i curl -sk http://localhost/health \
                                 | jq -Mr .cluster.ok) == "true" ]]; then
      if [[ $(docker exec $i evoke role) == master ]]; then
        current_master=$i
        return
      fi
    fi
  done
}

echo_version() {
  echo -n "Conjur Master appliance version: "
  docker exec -it $current_master cat /opt/conjur/etc/VERSION
}

timestamp() {
  echo "Timestamp:" $(date +%H:%M:%S)
}

main "$@"
