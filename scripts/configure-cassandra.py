#!/usr/bin/python

import os
import yaml


class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


userEditableSettings = ["cluster_name", "seeds", "listen_address",
                        "rpc_address", "endpoint_snitch"]

with open(os.environ["CASSANDRA_HOME"] + '/conf/cassandra.yaml') as file:
    configurationDocument = yaml.safe_load(file)

    for envKey, envValue in os.environ.iteritems():
        if envKey.startswith("CASSANDRA_"):
            if envKey == "CASSANDRA_HOME":
                continue

            configToChange = (envKey.split("CASSANDRA_", 1)[1]).lower()

            if configToChange in userEditableSettings:

                if configToChange == "seeds":
                    configurationDocument["seed_provider"][0]["parameters"][0]["seeds"] = envValue

                else:
                    configurationDocument[configToChange] = envValue
            else:
                print(bcolors.FAIL + envKey + " is not a valid setting!")

    with open(os.environ["CASSANDRA_HOME"] + '/conf/cassandra.yaml', 'w') as file:
        yaml.safe_dump(configurationDocument, file)
