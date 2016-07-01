#!/bin/bash

# export YARN_CONF_DIR=`pwd`/spark-client-config
# export HADOOP_USER_NAME=root

RUNNING=$(docker inspect --format="{{ .State.Running }}" kafka 2> /dev/null)
if [[ $? -eq 1 ]]; then
    docker run \
        -d \
        -p 2181:2181 \
        -p 9092:9092 \
        --name kafka \
        --env ADVERTISED_HOST="127.0.0.1" \
        --env ADVERTISED_PORT=9092 \
        spotify/kafka
elif [[ ${RUNNING} == "false" ]]; then
    docker start kafka
fi

RUNNING=$(docker inspect --format="{{ .State.Running }}" spark 2> /dev/null)
if [[ $? -eq 1 ]]; then
    docker run \
        -d \
        -h localhost \
        -p 22:22 \
        -p 8030:8030 \
        -p 8040:8040 \
        -p 8042:8042 \
        -p 8088:8088 \
        -p 49707:49707 \
        -p 50010:50010 \
        -p 50020:50020 \
        -p 50070:50070 \
        -p 50075:50075 \
        -p 50090:50090 \
        --name spark \
        sequenceiq/spark:1.6.0 \
        -d
elif [[ ${RUNNING} == "false" ]]; then
    docker start spark
fi