FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends openjdk-8-jre-headless

# Copy necessary scripts + configuration
COPY scripts /tmp/
RUN chmod +x /tmp/*.sh && \
    mv /tmp/*.sh /usr/bin && \
    rm -rf /tmp/*.sh

# Install Cassabdra
# ADD http://ftp.download-by.net/apache/cassandra/3.11.5/apache-cassandra-3.11.5-bin.tar.gz /opt/
COPY ./apache-cassandra-3.11.5-bin.tar.gz /opt/
RUN cd /opt && \
    tar -xzf apache-cassandra-3.11.5-bin.tar.gz && \
    mv apache-cassandra-3.11.5 cassandra && \
    rm -rf /opt/apache-cassandra-3.11.5-bin.tar.gz && \
    mkdir /data && mkdir /data/cassandra

HEALTHCHECK --interval=30s --timeout=20s --start-period=15s --retries=2 CMD [ "healthcheck.sh" ]

WORKDIR /opt/cassandra

CMD [ "start.sh" ]