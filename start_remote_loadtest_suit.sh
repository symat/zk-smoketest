#!/bin/bash

# PARAMETERS you can overwrite

export ZK_SERVER_HOSTS=${ZK_SERVER_HOSTS:-"mszalay-zk-loadtest-1.vpc.cloudera.com mszalay-zk-loadtest-2.vpc.cloudera.com mszalay-zk-loadtest-3.vpc.cloudera.com"}
export LOAD_GENERATOR_HOST=${LOAD_GENERATOR_HOST:-"mszalay-zk-loadtest-6.vpc.cloudera.com"}
export LOAD_GENERATOR_USE_SSL="true"
#export ADDITIONAL_LOADTEST_OPTIONS="--debug"

OUTPUT_FILE='loadtest_results.csv'
LOG_FILE='remote_loadtest.log'

ZK_EXTRA_JVM_ARGS=""


function print_header {
  HEADER="ZooKeeper version"
  HEADER="$HEADER,Number of servers"
  HEADER="$HEADER,ZNode size (KB)"
  HEADER="$HEADER,ZNode count"
  HEADER="$HEADER,Avg. data folder size (MB)"
  HEADER="$HEADER,Max memory consumption (MB)"
  HEADER="$HEADER,Avg. CPU load (%)"
  HEADER="$HEADER,Load: create permanent znodes (ms/ops)"
  HEADER="$HEADER,Load: set permanent znodes (ms/ops)"
  HEADER="$HEADER,Load: get permanent znodes (ms/ops)"
  HEADER="$HEADER,Load: delete permanent znodes (ms/ops)"
  HEADER="$HEADER,Load: create ephemeral znodes (ms/ops)"
  HEADER="$HEADER,Load: watch ephemeral znodes (ms/ops)"
  HEADER="$HEADER,Load: delete ephemeral znodes (ms/ops)"
  echo $HEADER >> $OUTPUT_FILE
}


function start_load_test {
  ZK_VERSION=$1 ZNODE_SIZE_KB=$2 ZNODE_COUNT=$3 ZK_EXTRA_JVM_ARGS=$ZK_EXTRA_JVM_ARGS ./start_single_remote_loadtest.sh 2>&1 | tee -a $LOG_FILE

  RESULTS=`cat $LOG_FILE | grep "=== generate output" -A 1 | tail -n1`
  echo $RESULTS >> $OUTPUT_FILE
}



print_header

for zk in 3.5.5_ZOOKEEPER-2122
do

  for znode_count in 50000 100000 150000
  do
    start_load_test $zk 10 $znode_count
  done

  for znode_size_kb in 25 50 75 100 125
  do
    start_load_test $zk $znode_size_kb 10000
  done
done