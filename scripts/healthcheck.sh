#!/bin/bash

cassandraProcess=$(ps -x | grep java | grep cassandra)

# If kafkaProcess is not empty
if ! [[ -z "$cassandraProcess" ]]; then
    # Check status

    cassandraStatus=$(echo $($CASSANDRA_HOME/bin/nodetool status))

    if [[ $cassandraStatus == *"'Connection refused (Connection refused)"* ]]; then
        echo " ERROR Unable to connect"
        exit 1
    fi

    # Create healthcheck keyspace - Hostname unique for this cassandra instance
    keyspaceName="TEST_KEYSPACE_HEALTHCHECK_$HOSTNAME"

    echo "CREATE KEYSPACE $keyspaceName WITH replication = {'class':'SimpleStrategy', 'replication_factor' : 1};" | $CASSANDRA_HOME/bin/cqlsh $CASSANDRA_RPC_ADDRESS -u cassandra -p cassandra

    tableName="TEST_TABLE_HEALTCHECK_$HOSTNAME"

    echo "CREATE TABLE $keyspaceName.$tableName(healthcheck_id int PRIMARY KEY, data text);" | $CASSANDRA_HOME/bin/cqlsh $CASSANDRA_RPC_ADDRESS -u cassandra -p cassandra

    echo "INSERT INTO $keyspaceName.$tableName(healthcheck_id, data) VALUES (1, 'test');" | $CASSANDRA_HOME/bin/cqlsh $CASSANDRA_RPC_ADDRESS -u cassandra -p cassandra
    
    insertVerification=$(echo "SELECT * FROM $keyspaceName.$tableName WHERE healthcheck_id=1;" | $CASSANDRA_HOME/bin/cqlsh $CASSANDRA_RPC_ADDRESS -u cassandra -p cassandra)
	
    # Test, if insert verification is empty, then fail
    if [[ -z "$insertVerification" ]]; then
        echo " ERROR Inserting data test failed "
        exit 1
    fi

    # Clean up
    echo "DROP KEYSPACE $keyspaceName;" | $CASSANDRA_HOME/bin/cqlsh $CASSANDRA_RPC_ADDRESS -u cassandra -p cassandra

    echo " OK "
    exit 0
fi

echo " CASSANDRA SERVER NOT RUNNING PROPERLY "
exit 1
