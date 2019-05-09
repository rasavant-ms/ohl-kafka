# Kafka OpenHack Lite: Python producer

This sample produces the same output as the [.NET Version](../producer-app-challenge1/Challenge1-producer/Program.cs), except written in Python.

## Running locally

In order to run this locally, you need to have Python 3.6+ installed. The requirements file is included and can be used as usual:

```shell
pip3 install -r requirements.txt
```

The libraries required should be: FreeTDS and librdkafka.

# Installing from a fresh Ubuntu machine

```shell
sudo apt-get update
sudo apt install python-pip
sudo apt install unixodbc-dev
pip install pyodbc
pip install -r requirements.txt
```

Follow the instructions [here](https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-2017#ubuntu-1404-1604-1710-and-1804) to install the SQL server driver for Linux/Ubuntu.

# Usage

You can now run the script to see the available options:

```shell
usage: producer.py [-h] [-c CONFIG_FILE] -s SQL_HOST -u SQL_USERNAME -p
                   SQL_PASSWORD -d SQL_DB -b BROKERS -t TOPIC [-v]

Args that start with '--' (eg. -s) can also be set in a config file (specified
via -c). Config file syntax allows: key=value, flag=true, stuff=[a,b,c] (for
details, see syntax at https://goo.gl/R74nmi). If an arg is specified in more
than one place, then commandline values override environment variables which
override config file values which override defaults.

optional arguments:
  -h, --help            show this help message and exit
  -c CONFIG_FILE, --config-file CONFIG_FILE
                        Config file path to use instead of ENV or command line
  -s SQL_HOST, --sql-host SQL_HOST
                        SQL server source for badge events [env var: SQL_HOST]
  -u SQL_USERNAME, --sql-username SQL_USERNAME
                        SQL server username. Use <name@servername> not
                        <name@serverFQDN>. [env var: SQL_USERNAME]
  -p SQL_PASSWORD, --sql-password SQL_PASSWORD
                        SQL server password [env var: SQL_PASSWORD]
  -d SQL_DB, --sql-db SQL_DB
                        Database on SQL server [env var: SQL_DB]
  -b BROKERS, --brokers BROKERS
                        Kafka brokers to connect to OR Event Hubs connection
                        string [env var: KAFKA_BROKERS]
  -t TOPIC, --topic TOPIC
                        Kafka topic to write to [env var: KAFKA_TOPIC]
  -v, --verbose         Extra output, including passwords and connection
                        strings [env var: PRODUCER_VERBOSE]
```

You can supply any argument through the command line, or through any of the environment variables listed above. 

```shell
SQL_HOST=contoso.databases.windows.net SQL_USERNAME=myuser ... python producer.py
```

They can also be set using a config file, using [settings.conf](./settings.conf) as a template.

```shell
python producer.py -c settings.conf
```

## Running in Docker

The docker image can be built using the usual build command:

```shell
docker build -t ohkl-py-c1 .
```

And then run with:

```shell
docker run --rm -it -v $(pwd):/src ohkl-py-c1 -v -c /src/settings.conf
```

Or with environment variables:

```shell
docker run --rm -it -e "SQL_HOST=contoso.databases.windows.net" ... ohkl-py-c1
```

Alternatively you can use the prebuilt image available at ``slyons/ohkl-py-c1-v2``, just substitute it in any of the above commands.
