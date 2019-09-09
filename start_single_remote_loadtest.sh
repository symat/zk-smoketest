#!/bin/bash

# PARAMETERS you can overwrite

ZK_SERVER_HOSTS=${ZK_SERVER_HOSTS:-"mszalay-zk-loadtest-1.vpc.cloudera.com mszalay-zk-loadtest-2.vpc.cloudera.com mszalay-zk-loadtest-3.vpc.cloudera.com"}
LOAD_GENERATOR_HOST=${LOAD_GENERATOR_HOST:-"mszalay-zk-loadtest-6.vpc.cloudera.com"}

ZK_VERSION=${ZK_VERSION:-"3.4.14"}
ZNODE_SIZE_KB=${ZNODE_SIZE_KB:-1}
ZNODE_COUNT=${ZNODE_COUNT:-10000}

echo "=== parameters:"
echo "   - ZK_VERSION: $ZK_VERSION"
echo "   - ZNODE_SIZE_KB: $ZNODE_SIZE_KB"
echo "   - ZNODE_COUNT: $ZNODE_COUNT"
echo "   - ZK_SERVER_HOSTS: $ZK_SERVER_HOSTS"
echo "   - LOAD_GENERATOR_HOST: $LOAD_GENERATOR_HOST"


echo "=== generate zoo.cfg file"
rm -f /tmp/zoo.cfg && cp ./zoo.cfg.template /tmp/zoo.cfg
echo "" >> /tmp/zoo.cfg
myid=0
for server in $ZK_SERVER_HOSTS
do
  myid=$((myid+1))
  echo "server.${myid}=${server}:2888:3888" >> /tmp/zoo.cfg
done


echo "=== upload zoo.cfg files"
for server in $ZK_SERVER_HOSTS
do
  scp /tmp/zoo.cfg $server:/root/zookeeper/
done


echo "=== sync zookeeper loadtest tool and necessary libs"
rsync -r -a -v -e ssh --delete ./ $LOAD_GENERATOR_HOST:/root/zk-smoketest


echo "=== stop the zk processes"
for server in $ZK_SERVER_HOSTS
do
  ssh $server 'kill `pidof java`'
done


echo "=== cleanup logs / data folders and start the zk processes in the background"
myid=0
for server in $ZK_SERVER_HOSTS
do
  myid=$((myid+1))
  ssh $server "/root/zookeeper/start_zk.sh $ZK_VERSION $myid"
done


echo "=== wait a bit to make sure zookeeper server started"
sleep 15

echo "=== start the load generator"
ssh $LOAD_GENERATOR_HOST "cd /root/zk-smoketest && ./loadtest.sh $ZK_VERSION '$ZK_SERVER_HOSTS' $ZNODE_SIZE_KB $ZNODE_COUNT"


echo "=== stop the zk processes"
for server in $ZK_SERVER_HOSTS
do
  ssh $server 'kill `pidof java`'
done


echo "=== fetch logs from the load test tool"
scp $LOAD_GENERATOR_HOST:/root/zk-smoketest/*.log.txt ./
LOADTEST_SUMMARY=`ssh $LOAD_GENERATOR_HOST 'cat /root/zk-smoketest/zk_latencies_summary.csv'`



echo "=== get folder size"
SUM_FOLDER_SIZE_KB=0
NUMBER_OF_SERVERS=0
for server in $ZK_SERVER_HOSTS
do
  NUMBER_OF_SERVERS=$((NUMBER_OF_SERVERS + 1))
  FOLDER_SIZE_KB=`ssh $server 'du -s /var/lib/zookeeper | cut -f1'`
  SUM_FOLDER_SIZE_KB=$((SUM_FOLDER_SIZE_KB + FOLDER_SIZE_KB))
done
AVG_FOLDER_SIZE_KB=$((SUM_FOLDER_SIZE_KB / NUMBER_OF_SERVERS))
AVG_FOLDER_SIZE_MB=$((AVG_FOLDER_SIZE_KB / 1024))


echo "=== get avg cpu load"
SUM_AVG_CPU_LOAD=0
for server in $ZK_SERVER_HOSTS
do
  AVG_CPU_LOAD=`ssh $server 'cat /root/zookeeper/zk.log | grep ===avg_cpu | cut -d : -f 2'`
  AVG_CPU_LOAD=${AVG_CPU_LOAD%\%}
  SUM_AVG_CPU_LOAD=$((SUM_AVG_CPU_LOAD + AVG_CPU_LOAD))
done
AVG_CPU_LOAD=$((SUM_AVG_CPU_LOAD / NUMBER_OF_SERVERS))


echo "=== get max memory"
MAX_MAX_MEMORY_KB=0
for server in $ZK_SERVER_HOSTS
do
  MAX_MEMORY_KB=`ssh $server 'cat /root/zookeeper/zk.log | grep ===max_mem | cut -d : -f 2'`
  if (( $MAX_MAX_MEMORY_KB < $MAX_MEMORY_KB )); then
    MAX_MAX_MEMORY_KB=$MAX_MEMORY_KB
  fi
done
MAX_MAX_MEMORY_MB=$((MAX_MEMORY_KB / 1024))


echo "=== generate output"
echo "$ZK_VERSION,$NUMBER_OF_SERVERS,$ZNODE_SIZE_KB,$ZNODE_COUNT,$AVG_FOLDER_SIZE_MB,$MAX_MAX_MEMORY_MB,$AVG_CPU_LOAD,$LOADTEST_SUMMARY"
