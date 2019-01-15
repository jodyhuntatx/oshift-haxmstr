# ans-cmaster-cluster/failover

These scripts will create failover conditions in a Conjur master cluster by pausing the current master for a specified number of seconds, then unpausing it. This simulates a network outage - the most common issue in distributed system coordination. On failover, the current master will be expelled from the cluster state, even if it is still functional to prevent split brain scenarios. One of the standbys will self-promote to be the new Master. Failed master nodes can be replaced as standby nodes with the same name as the failed Master. Thus, the cluster has three nodes that always have the same names but roles may change with failover cycles.

Directory contents:
 - 0_induceFailover.sh - takes one argument specifying number of seconds to pause current Conjur Master
 - 1_replaceStandby.sh - takes one argument specifying Conjur node name to replace as a Standby node
 - 2_checkCluster.sh - generates diagnostic information about current cluster state
 - 3_checkReplicationLagZero.sh - monitors cluster until replication lag goes to zero
 - conjurInduceFailover.yml - playbook to induce failover
 - conjurReplaceStandby.yml - playbook to replace standby
 - conjurCheckCluster.yml - playbook to generate diagnostic info
 - conjurCheckReplicationLagZero.yml - playbook to monitor replication lag
 - check_cluster.sh - script to generate diagnostic info
 - find_master.sh - script to produce cluster role info
 - check_replication.sh - script to monitor replication lag
 - collect_logs.sh - script that must be scp'd to host to collect Conjur node logs for debugging
