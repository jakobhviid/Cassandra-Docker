#!/bin/bash

echo "INFO Configuring Cassandra"

configure-cassandra.py

echo "INFO Starting Cassandra"

# avoid swapping
sysctl vm.swappiness=0

/opt/cassandra/bin/cassandra -f -R