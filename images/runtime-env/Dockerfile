FROM maven:3.9.12-eclipse-temurin-25-alpine as java-entrypoint
WORKDIR /root
COPY entrypoint ./
RUN mvn -T 1C package

FROM tomcat:11.0.18-jdk25-temurin-noble
LABEL maintainer="Neoskop DevOps <devops@neoskop.de>"

# Ensure probe dependencies exist across Debian/Ubuntu and Alpine-based variants.
RUN set -eux; \
    if command -v apt-get >/dev/null 2>&1; then \
      apt-get update; \
      apt-get install -y --no-install-recommends curl; \
      rm -rf /var/lib/apt/lists/*; \
    elif command -v apk >/dev/null 2>&1; then \
      apk add --no-cache curl; \
    else \
      echo "No supported package manager found to install curl" >&2; \
      exit 1; \
    fi

# Setup custom entrypoint
COPY --from=java-entrypoint /root/target/docker-entrypoint.jar /usr/local/bin

# Setup Tomcat config template
RUN mkdir -p $CATALINA_HOME/conf/Catalina/localhost

# Overwrite server.xml
COPY server.xml $CATALINA_HOME/conf/

# Clear webapps dir
RUN rm -rf webapps/*

# Prepare scripts
COPY bin/* /usr/local/bin/

# Setup Tomcat user
RUN useradd -ms /bin/bash -d /home/tomcat tomcat && chown -R tomcat:tomcat .
USER tomcat

# Set custom tika config to speed up startup
COPY tika-config.xml /home/tomcat/
ENV TIKA_CONFIG=/home/tomcat/tika-config.xml

# Prepare tmp dir
RUN mkdir -p /home/tomcat/magnolia_tmp && \
    chmod -R 0777 /home/tomcat/magnolia_tmp

# Prepare datastore dir
RUN mkdir -p /home/tomcat/magnolia_datastore && \
    chmod -R 0777 /home/tomcat/magnolia_datastore

# Prepare light modules dir
RUN mkdir -p /home/tomcat/light-modules

# Set workdir
WORKDIR /home/tomcat

# Expose port 8080 for http access and 5005 for debugging
EXPOSE 8080 5005

CMD ["/usr/local/bin/run.sh"]
VOLUME [ "/home/tomcat/magnolia_tmp", "/home/tomcat/magnolia_datastore" ]
