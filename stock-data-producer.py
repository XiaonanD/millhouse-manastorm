from googlefinance import getQuotes
from kafka import KafkaProducer
from kafka.errors import KafkaError, KafkaTimeoutError

import argparse
import atexit
import logging
import json
import schedule
import time

TOPIC_NAME = 'stock-analyzer'

producer = KafkaProducer(
    bootstrap_servers='127.0.0.1:9092'
)

logger_format = '%(asctime)-15s %(message)s'
logging.basicConfig(format=logger_format)
logger = logging.getLogger('stock-data-producer')
logger.setLevel(logging.DEBUG)


def fetch_price(symbol):
    logger.debug('Start to fetch stock price for %s', symbol)
    try:
        price = json.dumps(getQuotes(symbol))
        producer.send(topic=TOPIC_NAME, value=price, timestamp_ms=time.time())
        logger.debug('Sent stock price for %s to Kafka', symbol)
    except KafkaTimeoutError as timeout_error:
        logger.warn('Failed to send stock price for %s to kafka, caused by: %s', (symbol, timeout_error.message))
    except Exception as e:
        logger.warn('Failed to fetch stock price for %s, caused by: %s', (symbol, e.message))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('symbol', help='the symbol of the stock to collect')
    args = parser.parse_args()
    symbol = args.symbol

    schedule.every(1).second.do(fetch_price, symbol)


    def shutdown_hook():
        try:
            logger.info('Flushing pending messages to kafka, timeout is set to 10s')
            producer.flush(10)
            logger.info('Finish flushing pending messages to kafka')
        except KafkaError as kafka_error:
            logger.warn('Failed to flush pending messages to kafka, caused by: %s', kafka_error.message)
        finally:
            try:
                logger.info('Closing kafka connection')
                producer.close(10)
            except Exception as e:
                logger.warn('Failed to close kafka connection, caused by: %s', e.message)

    atexit.register(shutdown_hook)

    while True:
        schedule.run_pending()
        time.sleep(1)

