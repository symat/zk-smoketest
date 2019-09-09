#!/bin/bash

ZK_VERSION=$1
ZK_CLUSTER_NODES=$2
NATIVE_LIBS="lib-zk_${ZK_VERSION}-py_2.7.5-x86_64"
ZNODE_SIZE_KB=$3
ZNODE_SIZE_BYTE=$((1024*${ZNODE_SIZE_KB}))
ZNODE_COUNT=$4
WATCHERS_PER_ZNODE=1

echo "loadtest execution error" > zk_latencies_summary.csv
rm ./*.log.txt 

SERVERS=""
ZK_CLUSTER_SIZE=0
for server in $ZK_CLUSTER_NODES
do
  ZK_CLUSTER_SIZE=$((ZK_CLUSTER_SIZE+1))
  if [ -z "$SERVERS" ]; then
    SERVERS="${server}:2181"
  else
    SERVERS="$SERVERS,${server}:2181"
  fi
done
echo "servers: $SERVERS"


export PYTHONPATH=$NATIVE_LIBS
export LD_LIBRARY_PATH=$NATIVE_LIBS

LOGFILE="./zk_latencies_zk_${ZK_CLUSTER_SIZE}servers_ver${ZK_VERSION}_${ZNODE_COUNT}znodes_${ZNODE_SIZE_KB}KB_${WATCHERS_PER_ZNODE}watchers.log.txt"

./zk-latencies.py --servers $SERVERS --znode_count=$ZNODE_COUNT --znode_size=$ZNODE_SIZE_BYTE --watch_multiple=$WATCHERS_PER_ZNODE 2>&1 | tee $LOGFILE

cat $LOGFILE | grep "summary" -A 1 | tail -n1 > zk_latencies_summary.csv
