#!/bin/bash

echo "INFO Configuring Cassandra"

configure-cassandra.py

echo "INFO Starting Cassandra"

# avoid swapping
sysctl vm.swappiness=0
sysctl vm.max_map_count=1048575


/opt/cassandra/bin/cassandra -f -R