#!/bin/bash

# If neither username or password is set as environment variabel
if [[ -z "$CASSANDRA_USERNAME" || -z "$CASSANDRA_PASSWORD" ]]; then
    echo "WARN - Using default user 'cassandra' with password 'cassandra'. This is very unsafe"
    exit 0
fi

# If one or both of username and password is set, a new user will be made and default user 'cassandra' dropped

# if cassandra_username is not set
if [ -z "$CASSANDRA_USERNAME" ]; then
    echo "INFO - using default cassandra username - 'superuser-username'"
    CASSANDRA_USERNAME="superuser-username"
fi

# If cassandra_password is not set
if [ -z "$CASSANDRA_PASSWORD" ]; then
    echo "INFO - using default cassandra password - 'superuser-password'"
    CASSANDRA_PASSWORD="superuser-password"
fi

echo "INFO - Creating superuser with username and password. This should only be done once pr. cluster"

echo "CREATE ROLE "$CASSANDRA_USERNAME" WITH PASSWORD = '"$CASSANDRA_PASSWORD"' 
    AND SUPERUSER = true 
    AND LOGIN = true;" | $CASSANDRA_HOME/bin/cqlsh -u cassandra -p cassandra $CASSANDRA_RPC_ADDRESS

echo "INFO - Dropping default user 'cassandra'"

echo "DROP ROLE cassandra;" | $CASSANDRA_HOME/bin/cqlsh -u $CASSANDRA_USERNAME -p $CASSANDRA_PASSWORD $CASSANDRA_RPC_ADDRESS
