FROM python:3.6.8-stretch

RUN apt-get update \
        && apt-get install -y curl apt-transport-https gnupg2 \
        && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
        && curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list \
        && apt-get update \
        && ACCEPT_EULA=Y apt-get install -y unixodbc unixodbc-dev msodbcsql17 mssql-tools software-properties-common

RUN wget -qO - https://packages.confluent.io/deb/5.2/archive.key | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://packages.confluent.io/deb/5.2 stable main"
RUN apt-get install -y librdkafka1 librdkafka-dev

#RUN apk --no-cache add openssl freetds freetds-dev unixodbc unixodbc-dev
#RUN apk --no-cache add librdkafka librdkafka-dev
#RUN apk --no-cache --virtual .build-deps add build-base linux-headers gcc g++ libffi-dev openssl-dev freetds-dev 
#RUN apt-get update && apt-get install openssl libfreetds freetds-dev unixodbc unixodbc-dev 

COPY requirements.txt /

#RUN pip install Cython
#RUN pip install --no-binary pymssql pymssql
RUN pip install -r requirements.txt

COPY producer.py /
RUN python /producer.py -h

ENTRYPOINT ["python", "producer.py"]