export MESOS_NATIVE_JAVA_LIBRARY=/usr/local/lib/libmesos.dylib
http://ocw.mit.edu/ans7870/6/6.006/s08/lecturenotes/files/t8.shakespeare.txt

spark-submit --jars /usr/local/spark/spark-1.6.2/external/kafka-assembly/target/scala-2.10/spark-streaming-kafka-assembly-1.6.2.jar simple-stream-processing.py stock-analyzer average-stock-price 192.168.99.100:9092