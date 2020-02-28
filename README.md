# How to use

Two docker-compose files have been provided as examples.
**Note:** The container takes a while to start up, when the container has a 'healthy' status, it is running. Expect around 30-60 seconds start up time.

#### Docker-compose.single.yml

This docker-compose demonstrates deployment of a single cassanda node (for development purposes). Not much configuration is needed, but can be done if defaults aren't enough for your use-case ([configurations](#configurations))

```
version: "3"

services:
  cassandra:
    image: cfei/cassandra
    container_name: cassandra
    ports:
      - 9042:9042
    volumes:
      - ./data:/opt/cassandra/data
      - ./logs:/opt/cassandra/logs
    restart: always
```

#### Docker-compose.cluster.yml

This docker-compose demonstrates deployment of three cassandra nodes (for production purposes). Ideally the three nodes should **not** be running on the same machine for proper fault-tolerance.
For a clustered setup, a few more configurations are needed. ([configurations](#configurations)). **Please note the following:**

- cassandra1, cassandra2, cassandra3 should be replaced by either DNS-resolvable hostnames or IP-addresses of the server on which the cassandra node is running.
- CASSANDRA_STORAGE_PORT is not mandatory to set if the nodes are running on different machines, however, this docker-compose only acts as an example and for inter-node (node-node) communication to work they need to be able to communicate.
- CASSANDRA_MAX_HEAP_SIZE and CASSANDRA_HEAP_NEWSIZE might be necessary to change depending on hardware and docker configuration. Cassandra ideally should have a MAX_HEAP_SIZE of atleast 4Gb Ram.

```
version: "3"

services:
  cassandra1:
    image: cfei/cassandra
    container_name: cassandra1
    ports:
      - 9042:9042
      - 7000:7000
    environment:
      CASSANDRA_CLUSTER_NAME: "reference-cluster"
      CASSANDRA_SEEDS: "cassandra1,cassandra2,cassandra3"
      CASSANDRA_ENDPOINT_SNITCH: "GossipingPropertyFileSnitch"
      CASSANDRA_BROADCAST_ADDRESS: "cassandra1"
      CASSANDRA_DATACENTER: dc1Test
      CASSANDRA_RACK: rack1Test
      CASSANDRA_STORAGE_PORT: 7000
      CASSANDRA_MAX_HEAP_SIZE: 1G
      CASSANDRA_HEAP_NEWSIZE: 200M
    restart: always

  cassandra2:
    image: cfei/cassandra
    container_name: cassandra2
    ports:
      - 9043:9042
      - 7001:7001
    environment:
      CASSANDRA_CLUSTER_NAME: "reference-cluster"
      CASSANDRA_SEEDS: "cassandra1,cassandra2,cassandra3"
      CASSANDRA_ENDPOINT_SNITCH: "GossipingPropertyFileSnitch"
      CASSANDRA_BROADCAST_ADDRESS: "cassandra2"
      CASSANDRA_DATACENTER: dc1Test
      CASSANDRA_RACK: rack1Test
      CASSANDRA_STORAGE_PORT: 7001
      CASSANDRA_MAX_HEAP_SIZE: 1G
      CASSANDRA_HEAP_NEWSIZE: 200M
    restart: always

  cassandra3:
    image: cfei/cassandra
    container_name: cassandra3
    ports:
      - 9044:9042
      - 7002:7002
    environment:
      CASSANDRA_CLUSTER_NAME: "reference-cluster"
      CASSANDRA_SEEDS: "cassandra1,cassandra2,cassandra3"
      CASSANDRA_ENDPOINT_SNITCH: "GossipingPropertyFileSnitch"
      CASSANDRA_BROADCAST_ADDRESS: "cassandra3"
      CASSANDRA_DATACENTER: dc1Test
      CASSANDRA_RACK: rack1Test
      CASSANDRA_STORAGE_PORT: 7002
      CASSANDRA_MAX_HEAP_SIZE: 1G
      CASSANDRA_HEAP_NEWSIZE: 200M
    restart: always

```

# Configurations

**Configurations required for a clustered setup**

- `CASSANDRA_CLUSTER_NAME`: Name of the cluster the Cassandra node will connect to.

- `CASSANDRA_SEEDS`: Comma seperated list of IP-addresses og DNS-resolvable hostnames. Used for communicating (gossiping) with other cassandra nodes. It is important to also insert the Cassandra Nodes' own IP-address.

- `CASSANDRA_ENDPOINT_SNITCH`: Sets the snitch implementation. Used for Casandra nodes to learn each other's network configurations and for datacenter and rack configurations when using "GossipingPropertyFileSnitch".

  **Note:** GossipingPropertyFileSnitch is the go-to endpoint_snitch for a cassandra cluster in production. [For clarification read here](http://cassandra.apache.org/doc/latest/configuration/cassandra_config_file.html#endpoint-snitch).

- `CASSANDRA_BROADCAST_ADDRESS`: Advertised IP-address that other Cassandra nodes should use to locate the node. This is really important to set correctly in a docker container when it's a cluster spread over mulitple hosts as the docker IP-address is not visible to any other than the host machine.

  **Note:** `broadcast_rpc_address` is set to the same value as `CASSANDRA_BROADCAST_ADDRESS` for client connections.

- `CASSANDRA_DATACENTER`: Which datacenter the node should be in. Only has an effect when using endpoint_snitch "GossipingPropertyFileSnitch".

- `CASSANDRA_RACK`: Which rack the node should be in. Only has an effect when using endpoint_snitch "GossipingPropertyFileSnitch".

**Configurations with defaults for a clustered setup**

- `CASSANDRA_STORAGE_PORT`: Internode communication (node-node communicating (gossiping). This is not mandatory to set if the nodes are running on different machines. Default is 7000.

- `CASSANDRA_LISTEN_ADDRESS`: The IP-address the node should listen on for connections. Defaults to the IP-address of the container.

- `CASSANDRA_RPC_ADDRESS`: The IP-address the node binds the native transport server to. Used for client connections.

- `CASSANDRA_NUM_TOKENS`: The number of tokens on the node. The more tokens the more data the node will store compared to other cassandra nodes. This is relevant if your cassandra nodes have different hardware ressources, you might want to have a higher number of tokens on the better performing machines. Defaults to 256. [For clarification read here](http://cassandra.apache.org/doc/latest/configuration/cassandra_config_file.html#num-tokens).

- `CASSANDRA_AUTHENTICATOR`: Authentication of users. Defaults to 'PasswordAuthenticator'. Can be set to 'AllowAllAuthenticator' to disable logins, not recommended. ([Authentication & Authorization adjustments](#authentication--authorization))

- `CASSANDRA_AUTHORIZER`: Authorization of users to limit permissions. Defaults to 'CassandraAuthorizer'. Can be set to 'AllowAllAuthorizer' to disable authorization, not recommended. ([Authentication & Authorization adjustments](#authentication--authorization))

- `CASSANDRA_MAX_HEAP_SIZE & CASSANDRA_HEAP_NEWSIZE`: Cassandra automatically calculates the MAX_HEAP_SIZE and HEAP_NEWSIZE which can be a problem in some scenarios. This could for example be if cassandra doesn't use all avaiable ram on the host machine, or if it uses too much so that it Docker kills other containers to provide Cassandra with enough ram.
 **Note:** Don't run multiple cassandra containers on the same machine! It will give better performance to create 1 cassandra container with access to all the CPU, RAM and disk IO resources, than to create multiple cassandra containers on the same host but with limited access to RAM, CPU and disk IO.

# Authentication & Authorization

By default this image comes out of the box with cassandra authentication, authorization and role management. This means that when starting a node you will have access to a default superuser:

**username**: cassandra

**password**: cassandra

This is **extremely** unsafe and should be configured! Ideally a new super user is created with username and password. Then the default superuser should be dropped or atleast have the password altered or dropped completly.

### Guide to do so:

1. Log in to CQL shell with the default superuser:

   `cqlsh -u cassandra -p cassandra`

2. Create new superuser with secure usernamer and password:

   `CREATE ROLE <secure_username_here> WITH SUPERUSER = true AND LOGIN = true AND PASSWORD = '<secure_password_here>';`

3. Log into CQL shell with your new superuser:

   `cqlsh -u <secure_username_here> -p <secure_password_here>`

4. Ideally dropping the default superuser account or atleast changing the password:

   `DROP ROLE cassandra;`

   OR

   `ALTER ROLE cassandra WITH SUPERUSER = false AND PASSWORD = '<another_secure_password_here>';`

5. Verify changes have been made:

   `LIST ROLES;`

# Volumes
- `/opt/cassandra/data`: This is where Cassandra stores data files, commitlogs, hints and saved_caches, each in it's own seperate folder. So if you only want to create a volume with the actual data, the path would be `/opt/cassandra/data/data`. It is a good idea to simply just store everything inside this folder in case of container shutdown and recreation.

- `/opt/cassandra/logs`: This is where Cassandra stores log files for both debugging (debug.log), general understanding (system.log) and a standard Java garbage collection log (gc.log).
