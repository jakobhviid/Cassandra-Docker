FROM ubuntu:18.04

RUN apt update && \
    apt install -y --no-install-recommends openjdk-8-jre-headless && \
    apt install -y python python-pip && \
    pip install pyyaml

# Copy necessary scripts + configuration
COPY scripts /tmp/
RUN chmod +x /tmp/*.py || *.sh && \
    mv /tmp/* /usr/bin && \
    rm -rf /tmp/*

# Install Cassandra
# ADD http://ftp.download-by.net/apache/cassandra/3.11.5/apache-cassandra-3.11.5-bin.tar.gz /opt/
COPY ./apache-cassandra-3.11.5-bin.tar.gz /opt/
RUN cd /opt && \
    tar -xzf apache-cassandra-3.11.5-bin.tar.gz && \
    mv apache-cassandra-3.11.5 cassandra && \
    rm -rf /opt/apache-cassandra-3.11.5-bin.tar.gz

HEALTHCHECK --interval=30s --timeout=20s --start-period=15s --retries=2 CMD [ "healthcheck.sh" ]

VOLUME [ "/data/cassandra" ]

WORKDIR /opt/cassandra

RUN apt install nano -y

CMD [ "start.sh" ]