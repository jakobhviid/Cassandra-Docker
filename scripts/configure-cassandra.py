#!/usr/bin/python

import socket
import struct
import fcntl
import os
import sys
import yaml


def search_and_replace_in_file(filePath, searchString, replaceString):
    # Read in the file
    with open(filePath, 'r') as file:
        filedata = file.read()

    # Replace the target string
    filedata = filedata.replace(searchString, replaceString, 1)

    # Write the file out again
    with open(filePath, 'w') as file:
        file.write(filedata)


def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,  # SIOCGIFADDR
        struct.pack('256s', ifname[:15])
    )[20:24])


class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


userEditableSettings = ["cluster_name", "seeds", "listen_address", "rpc_address", "endpoint_snitch", "broadcast_address",
                        "datacenter", "rack", "num_tokens", "storage_port", "authenticator", "authorizer"]

defaultDockerIPUserSettings = ["listen_address",
                               "broadcast_rpc_address", "broadcast_address", "seeds"]

with open(os.environ["CASSANDRA_HOME"] + '/conf/cassandra.yaml') as file:
    configurationDocument = yaml.safe_load(file)

    environmentDictionary = os.environ.iteritems()

    settingsConfigured = []

    for envKey, envValue in environmentDictionary:
        if envKey.startswith("CASSANDRA_"):
            if envKey == "CASSANDRA_HOME":
                continue

            configToChange = (envKey.split("CASSANDRA_", 1)[1]).lower()

            # Making a list with all the settings configured which is checked later to check required settings
            settingsConfigured.append(configToChange)

            if configToChange in userEditableSettings:

                if configToChange == "seeds":
                    configurationDocument["seed_provider"][0]["parameters"][0]["seeds"] = envValue

                elif configToChange == "broadcast_address":
                    # When running in docker private IP is different then public IP, so these configurations are needed in order to gossip with other cassandra instances
                    configurationDocument["broadcast_address"] = envValue
                    configurationDocument["broadcast_rpc_address"] = envValue

                elif configToChange == "datacenter":
                    search_and_replace_in_file(
                        os.environ["CASSANDRA_HOME"] + '/conf/cassandra-rackdc.properties', 'dc=dc1', 'dc=' + envValue)  # TODO: Use wildcard instead for the search string
                elif configToChange == "rack":
                    # TODO: Use wildcard instead for the search string
                    search_and_replace_in_file(
                        os.environ["CASSANDRA_HOME"] + '/conf/cassandra-rackdc.properties', 'rack=rack1', 'rack=' + envValue)

                else:
                    configurationDocument[configToChange] = envValue
            else:
                print(bcolors.FAIL + "ERROR - " +
                      envKey + " is not a valid setting!")
                sys.exit(1)

    for defaultUserSetting in defaultDockerIPUserSettings:
        if defaultUserSetting in settingsConfigured:
            continue
        else:
            if defaultUserSetting == "seeds":
                configurationDocument["seed_provider"][0]["parameters"][0]["seeds"] = get_ip_address(
                    'eth0')
            else:
                configurationDocument[defaultUserSetting] = get_ip_address(
                    'eth0')
with open(os.environ["CASSANDRA_HOME"] + '/conf/cassandra.yaml', 'w') as file:
    yaml.safe_dump(configurationDocument, file)
