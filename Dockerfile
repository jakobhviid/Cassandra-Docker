FROM ubuntu:18.04

ENV CASSANDRA_HOME=/opt/cassandra

RUN apt update && \
    apt install -y --no-install-recommends openjdk-8-jre-headless && \
    apt install -y python python-pip && \
    pip install pyyaml

# Copy necessary scripts + configuration
COPY scripts /tmp/
RUN chmod +x /tmp/*.py && \
    chmod +x /tmp/*.sh && \
    mv /tmp/* /usr/bin && \
    rm -rf /tmp/*

# Install Cassandra
COPY ./apache-cassandra-3.11.5-bin.tar.gz configuration.yaml /opt/
RUN cd /opt && \
    tar -xzf apache-cassandra-3.11.5-bin.tar.gz && \
    mv apache-cassandra-3.11.5 ${CASSANDRA_HOME} && \
    rm -rf /opt/apache-cassandra-3.11.5-bin.tar.gz && \
    mv /opt/configuration.yaml ${CASSANDRA_HOME}/conf/cassandra.yaml

HEALTHCHECK --interval=45s --timeout=30s --start-period=60s --retries=3 CMD [ "healthcheck.sh" ]

EXPOSE 9042 7000

VOLUME [ "${CASSANDRA_HOME}/data", "${CASSANDRA_HOME}/logs" ]

WORKDIR ${CASSANDRA_HOME}

CMD [ "start.sh" ]