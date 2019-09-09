#!/bin/bash

export JVMFLAGS="-Djava.net.preferIPv4Stack=true -Dzookeeper.datadir.autocreate=true -Dcom.sun.management.jmxremote.authenticate=false  -Dcom.sun.management.jmxremote.ssl=false -Djute.maxbuffer=4194304 -Xms10g -Xmx10g"

export TIME="===\n===time results\n===\n===cmd:%C\n===real_time:%e\n===use_timer:%U\n===sys_time:%S\n===max_memory:%M\n===avg_memory:%K\n===avg_cpu:%P"

rm -f /root/zookeeper/zk.log
rm -Rf /var/lib/zookeeper/
mkdir -p /var/lib/zookeeper
echo "$2" > /var/lib/zookeeper/myid

nohup /bin/time /root/zookeeper/zookeeper-$1/bin/zkServer.sh start-foreground /root/zookeeper/zoo.cfg > /root/zookeeper/zk.log 2>&1 < /dev/null &
