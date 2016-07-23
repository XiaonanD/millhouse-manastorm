## run guide

### tools required
1. git  `git --version`
2. nodejs   `node --version`
3. npm  `npm --version`
4. python   `python --version`
5. pip  `pip --version`
6. java `java --version`
7. scala    `scala --version`
8. sbt  `sbt sbtVersion`
9. docker   `docker --version`
10. docker-machine   `docker-machine --version`

### clone and install dependencies
```sh
git clone https://github.com/UncleBarney/millhouse-manastorm.git

# - install python dependencies
pip install redis googlefinance kafka-python schedule

# - install nodejs dependencies
cd millhouse-manastorm/nodejs
npm install

# - install spark
wget http://d3kbcqa49mib13.cloudfront.net/spark-1.6.2.tgz
mkdir -p /usr/local/spark
mv spark-1.6.2.tar /usr/local/spark
cd /usr/local/spark && tar xvf spark-1.6.2.tar && cd spark-1.6.2
sbt -mem 2048 clean assembly

# - add spark executable to your PATH, add the following command to
# - your bashrc or zshrc
export PATH=$PATH:/usr/local/spark/spark-1.6.2/bin

# - run the following command to make sure your spark runs properly
spark-shell
```

### start docker-machine environment
```sh
# - create an empty vm to run docker daemon
docker-machine create -d virtualbox alpha
# - check if the vm is up and running
docker-machine ls
# - connect your terminal window to the docker daemon within vm
eval $(docker-machine env alpha)
# - check if docker command can connect
docker ps

cd millhouse-manastorm/provision/docker

# - if os tell you that it cannot find setup.sh, run the following
# - chmod +x setup.sh
./setup.sh alpha

# - then check if all the containers are up and running
# - you should see 6 containers running
docker ps
```

### run the stuff
```sh
# - under kafka folder
python simple-kafka-producer.py AAPL stock-analyzer `docker-machine ip alpha`:9092

# - under redis folder
python simple-redis-publisher.py stock-analyzer `docker-machine ip alpha`:9092 stock `docker-machine ip alpha` 6379

# - under nodejs folder
node index.js --port=3000 --redis_host=`docker-machine ip alpha` --redis_port=6379 --subscribe_topic=stock

# - under spark folder
spark-submit --jars /usr/local/spark/spark-1.6.2/external/kafka-assembly/target/scala-2.10/spark-streaming-kafka-assembly-1.6.2.jar simple-stream-processing.py stock-analyzer average-stock-price `docker-machine ip alpha`:9092
```