#!/bin/bash

ZK_EXTRA_JVM_ARGS=${3:-""}
ZK_DATA_FOLDER=/mnt/data/zookeeper


# in zookeeper startup scripts: -Xmx is set by ZK_SERVER_HEAP, but -Xms is not set
export ZK_SERVER_HEAP=10000
export JVMFLAGS="$ZK_EXTRA_JVM_ARGS -Djava.net.preferIPv4Stack=true -Dzookeeper.datadir.autocreate=true -Dcom.sun.management.jmxremote.authenticate=false  -Dcom.sun.management.jmxremote.ssl=false -Djute.maxbuffer=4194304 -Xms${ZK_SERVER_HEAP}m "

export TIME="===\n===time results\n===\n===cmd:%C\n===real_time:%e\n===use_timer:%U\n===sys_time:%S\n===max_memory:%M\n===avg_memory:%K\n===avg_cpu:%P"

rm -f /root/zookeeper/zk.log
rm -Rf ${ZK_DATA_FOLDER}/
mkdir -p ${ZK_DATA_FOLDER}
echo "$2" > ${ZK_DATA_FOLDER}/myid

nohup /bin/time /root/zookeeper/zookeeper-$1/bin/zkServer.sh start-foreground /root/zookeeper/zoo.cfg > /root/zookeeper/zk.log 2>&1 < /dev/null &
