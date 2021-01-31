#!/bin/bash

function cleanup(){
	/opt/cassandra/bin/nodetool stopdaemon
	local e1=$?
	echo "Cassandra Stopped"
	exit $e1
}

echo "INFO - Configuring Cassandra"

# Enable the use of environment variables CASSANDRA_MAX_HEAP_SIZE and CASSANDRA_HEAP_NEWSIZE
if ! [[ -z "$CASSANDRA_MAX_HEAP_SIZE" ]]; then
    export MAX_HEAP_SIZE="$CASSANDRA_MAX_HEAP_SIZE"
    unset CASSANDRA_MAX_HEAP_SIZE
fi

if ! [[ -z "$CASSANDRA_HEAP_NEWSIZE" ]]; then
    export HEAP_NEWSIZE="$CASSANDRA_HEAP_NEWSIZE"
    unset CASSANDRA_HEAP_NEWSIZE
fi

configure-cassandra.py

# If configure python script exits with an error, exit the whole container
if [ $? != 0 ]; then
    exit 1
fi

echo "INFO - Starting Cassandra"

# avoid swapping
sysctl vm.swappiness=0
sysctl vm.max_map_count=1048575

# -R force cassandra to run as root
/opt/cassandra/bin/cassandra -R

trap cleanup SIGTERM SIGINT

while true; do :; done