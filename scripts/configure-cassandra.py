#!/usr/bin/python

import yaml
import os

def getKey(confDoc, keys):
    for key in keys:
        # TODO: Make it possible to add new items to a list instead of replcaing already existing items
        if isinstance(confDoc, list):
            if (len(confDoc)-1) < key
                print("ERROR You cannot add an item to an array YET (TO BE IMPLEMENTED)")
                os._exit(1)
        confDoc = confDoc[key]

    return confDoc


def set_conf_doc(confDoc, keys, value):
    confDoc = getKey(confDoc, keys[:-1])
    confDoc[keys[-1]] = value


yamlArraySplitter = "-"
yamlDictionarySplitter = ":"

with open('/opt/cassandra/conf/cassandra.yaml') as file:
    configurationDocument = yaml.safe_load(file)

    for envKey, envValue in os.environ.iteritems():
        if envKey.startswith("CASSANDRA_"):
            configToChange = (envKey.split("CASSANDRA_", 1)[1]).lower()

            nestedConfigurationToChange = ""

            nestedKeys = []

            index = 0

            print("LENGTH IS " + str(len(configToChange)))

            while index < len(configToChange):
                character = configToChange[index]

                index += 1

                if character != yamlArraySplitter and character != yamlDictionarySplitter:
                    nestedConfigurationToChange += character
                    continue
                else:
                    if character == yamlDictionarySplitter:
                        continue

                    nestedKeys.append(nestedConfigurationToChange)
                    nestedConfigurationToChange = ""

                # Plus one because that is the index which the user wants to insert a configuration variable

                if character == yamlArraySplitter:
                    nestedKeys.append(int(configToChange[index]))
                    index = index + 1

            # Man kan teste for om det er null og hvis det er kan man append eller adde i stedet for
            if len(nestedConfigurationToChange) != 0:
                nestedKeys.append(nestedConfigurationToChange)

            print '[%s]' % ', '.join(map(str, nestedKeys))

            set_conf_doc(configurationDocument, nestedKeys, envValue)
            # configurationDocument["seed_provider"][0]["parameters"][0]["seeds"] = envValue

    with open('/opt/cassandra/conf/cassandra.yaml', 'w') as file:
        yaml.safe_dump(configurationDocument, file)
