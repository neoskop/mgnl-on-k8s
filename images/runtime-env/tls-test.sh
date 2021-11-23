#!/bin/bash
docker-compose start db
sleep 10
docker cp runtime-env_db_1:/var/lib/mysql/ca.pem ca.pem
rm -f truststore.jks
keytool -importcert -alias MySQLCACert -file ca.pem -keystore truststore.jks -storepass changedit -noprompt &>/dev/null
docker-compose -f docker-compose.tls.yml up