#!/bin/bash
set -e

if ! [ -d /home/tomcat/light-modules/mtk ] && [ -w /home/tomcat/light-modules ]; then
    mkdir -p /home/tomcat/light-modules/mtk/templates/pages/
    echo "visible: false" >/home/tomcat/light-modules/mtk/templates/pages/basic.yaml
fi

java -jar /usr/local/bin/docker-entrypoint.jar
export JAVA_OPTS="-Dlog4j2.formatMsgNoLookups=true -XX:InitialRAMPercentage=10 -XX:MaxRAMPercentage=80 -XX:MinRAMPercentage=50 -Dmagnolia.repositories.home=/home/tomcat/magnolia_tmp/repositories -Djava.awt.headless=true -Dfile.encoding=UTF-8 $JAVA_OPTS"
${CATALINA_HOME}/bin/catalina.sh run
