#!/bin/bash
set -e

if ! [ -d /home/tomcat/light-modules/mtk ] && [ -w /home/tomcat/light-modules ]; then
    mkdir -p /home/tomcat/light-modules/mtk/templates/pages/
    echo "visible: false" > /home/tomcat/light-modules/mtk/templates/pages/basic.yaml
fi

java -jar /usr/local/bin/docker-entrypoint.jar
export JAVA_OPTS="-Dmagnolia.repositories.home=/home/tomcat/magnolia_tmp/repositories -Djava.awt.headless=true -Dfile.encoding=UTF-8 -Xms1024m -Xmx2048m $JAVA_OPTS"
${CATALINA_HOME}/bin/catalina.sh run
