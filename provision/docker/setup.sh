#!/bin/bash

MACHINE_NAME=$1

IP=$(docker-machine ip ${MACHINE_NAME})

#
# - run a single zookeeper broker
#
echo "start zookeeper"
RUNNING=$(docker inspect --format="{{ .State.Running }}" zookeeper 2> /dev/null)
if [[ $? -eq 1 ]]; then
    docker run \
        -d \
        -p 2181:2181 \
        -p 2888:2888 \
        -p 3888:3888 \
        --name zookeeper \
        confluent/zookeeper
elif [[ ${RUNNING} == "false" ]]; then
    docker start zookeeper
fi

#
# - run the mesos master
#
echo "start mesos-master"
RUNNING=$(docker inspect --format="{{ .State.Running }}" mesos-master 2> /dev/null)
if [[ $? -eq 1 ]]; then
    docker run \
        -d \
        -p 5050:5050 \
        -e MESOS_HOSTNAME="${IP}" \
        -e MESOS_IP="${IP}" \
        -e MESOS_ZK="zk://${IP}:2181/mesos" \
        -e MESOS_PORT=5050 \
        -e MESOS_LOG_DIR="/var/log/mesos" \
        -e MESOS_QUORUM=1 \
        -e MESOS_REGISTRY="in_memory" \
        -e MESOS_WORK_DIR="/var/lib/mesos" \
        -e MESOS_ROLES="'*',slave_public" \
        --name mesos-master \
        --net="host" \
        mesosphere/mesos-master:0.28.0-2.0.16.ubuntu1404
elif [[ ${RUNNING} == "false" ]]; then
    docker start mesos-master
fi

#
# - run the mesos slave
#
echo "start mesos-slave"
RUNNING=$(docker inspect --format="{{ .State.Running }}" mesos-slave 2> /dev/null)
if [[ $? -eq 1 ]]; then
    docker run \
        -d \
        -p 5051:5051 \
        -p 40000-62000:10000-32000 \
        -e MESOS_HOSTNAME="${IP}" \
        -e MESOS_MASTER="zk://${IP}:2181/mesos" \
        -e MESOS_IP="${IP}" \
        -e MESOS_LOG_DIR="/var/log/mesos" \
        -e MESOS_LOGGING_LEVEL="INFO" \
        -e MESOS_PORT=5051 \
        -e MESOS_DEFAULT_ROLE="slave_public" \
        -e MESOS_RESOURCES="cpus:128;mem:204800;ports:[10000-32000]" \
        -e MESOS_CONTAINERIZERS="docker" \
        -e MESOS_EXECUTOR_REGISTRATION_TIMEOUT="5mins" \
        -e MESOS_DOCKER_SOCK="/var/run/docker.sock" \
        -e MESOS_CGROUPS_HIERARCHY="/sys/fs/cgroup" \
        -v /etc:/etc \
        -v /sys:/sys \
        -v /cgroup:/cgroup \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /usr/local/bin/docker:/bin/docker \
        --name mesos-slave \
        --net "host" \
        mesosphere/mesos-slave:0.28.0-2.0.16.ubuntu1404
elif [[ ${RUNNING} == "false" ]]; then
    docker start mesos-slave
fi

#
# - run the marathon framework
#
echo "start mesos marathon framework"
RUNNING=$(docker inspect --format="{{ .State.Running }}" marathon 2> /dev/null)
if [[ $? -eq 1 ]]; then
    docker run \
        -d \
        -p 8080:8080 \
        -e MARATHON_MESOS_ROLE="slave_public" \
        --name marathon \
        mesosphere/marathon:v1.1.1 \
        --master zk://${IP}:2181/mesos \
        --zk zk://${IP}:2181/marathon
elif [[ ${RUNNING} == "false" ]]; then
    docker start marathon
fi

#
# - run the kafka broker
#
echo "start kafka"
RUNNING=$(docker inspect --format="{{ .State.Running }}" kafka 2> /dev/null)
if [[ $? -eq 1 ]]; then
    docker run \
        -d \
        -p 9092:9092 \
        -e KAFKA_ADVERTISED_HOST_NAME="${IP}" \
        -e KAFKA_ADVERTISED_PORT=9092 \
        --name kafka \
        --link zookeeper:zookeeper \
        confluent/kafka
elif [[ ${RUNNING} == "false" ]]; then
    docker start kafka
fi

#
# - run the redis
#
echo "start redis"
RUNNING=$(docker inspect --format="{{ .State.Running }}" redis 2> /dev/null)
if [[ $? -eq 1 ]]; then
    docker run \
        -d \
        -p 6379:6379 \
        --name redis \
        redis:alpine
elif [[ ${RUNNING} == "false" ]]; then
    docker start redis
fi