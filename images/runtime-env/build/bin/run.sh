#!/bin/bash
java -jar /usr/local/bin/docker-entrypoint.jar
export JAVA_OPTS="-Dmagnolia.repositories.home=/home/tomcat/magnolia_tmp/repositories -Djava.awt.headless=true -Dfile.encoding=UTF-8 -Xms1024m -Xmx2048m $JAVA_OPTS"
${CATALINA_HOME}/bin/catalina.sh run
