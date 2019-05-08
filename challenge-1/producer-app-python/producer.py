import logging, configargparse, pyodbc, time, pdb, re, json, sys
from threading import Event
from confluent_kafka import Producer
from metrology import Metrology
from metrology.reporter import LoggerReporter

meter = Metrology.meter("messages")
successful = Metrology.counter("success")
errors = Metrology.meter("errors")
stop_event = Event()

def get_kafka_parameters(options):
    producer_config = {"bootstrap.servers":options.brokers, "message.timeout.ms":1000}
    match = re.findall("://([^/]+)/", options.brokers)
    if len(match) == 1:
        producer_config["bootstrap.servers"] = match[0] + ":9093"
        producer_config.update({
            'sasl.mechanisms': 'PLAIN',
            'security.protocol': 'SASL_SSL',
            "sasl.username": "$ConnectionString",
            "sasl.password": options.brokers
        })
    logging.debug("Using Kafka config: {}".format(json.dumps(producer_config)))
    return producer_config

def get_badge(options):
    #with pyodbc.connect(options.sql_host, options.sql_username, options.sql_password, options.sql_db) as conn:
    with pyodbc.connect(driver='{ODBC Driver 17 for SQL Server}',server=options.sql_host,database=options.sql_db, uid=options.sql_username, pwd=options.sql_password) as conn:
        with conn.cursor() as cursor:
            last = None
            while stop_event.is_set() is not True:
                cursor.execute("{ CALL Challenge1.GetBadge }")
                columns = [column[0] for column in cursor.description]
                results = []
                for row in cursor.fetchall():
                    results.append(dict(zip(columns, row)))
                res = results[0]
                if res == last:
                    return
                else:
                    yield res

def delivery_report(err, msg):
    if err is not None:
        errors.mark()
        logging.error(err)
        if errors.one_minute_rate > 20:
            logging.error("Number of failures over the last minute has reached 20, stopping.")
            stop_event.set()
    else:
        successful.increment()
    meter.mark()

def send_badge_event(options):
    producer_config = get_kafka_parameters(options)
    try:
        logging.info("Creating Kafka producer")
        producer = Producer(producer_config)
        logging.info("Sending events")
        for badge in get_badge(options):
            m = json.dumps(badge)
            producer.poll(0)
            producer.produce(options.topic, m, callback=delivery_report)
            time.sleep(0.01)
        producer.flush()
        return 0
    except Exception as e:
        logging.error("Some exception occurred:", e)
        stop_event.set()
        return 1


if __name__ == "__main__":
    p = configargparse.ArgParser()
    p.add("-c", "--config-file", is_config_file=True, help="Config file path to use instead of ENV or command line")
    p.add("-s", "--sql-host", required=True, env_var="SQL_HOST", help="SQL server source for badge events")
    p.add("-u", "--sql-username", required=True, env_var="SQL_USERNAME", help="SQL server username. Use <name@servername> not <name@serverFQDN>.")
    p.add("-p", "--sql-password", required=True, env_var="SQL_PASSWORD", help="SQL server password")
    p.add("-d", "--sql-db", required=True, env_var="SQL_DB", help="Database on SQL server")
    p.add("-b", "--brokers", required=True, env_var="KAFKA_BROKERS", help="Kafka brokers to connect to OR Event Hubs connection string")
    p.add("-t", "--topic", required=True, env_var="KAFKA_TOPIC", help="Kafka topic to write to")
    p.add("-v", "--verbose", action="store_true", env_var="PRODUCER_VERBOSE", help="Extra output, including passwords and connection strings")
    options = p.parse_args()
    loglevel = logging.DEBUG if options.verbose else logging.INFO
    logging.basicConfig(level=loglevel)
    logging.info("Starting OpenHack Kafka producer...")
    logging.debug(p.format_values())

    reporter = LoggerReporter(level=logging.INFO, interval=10)
    reporter.start()
    sys.exit(send_badge_event(options))