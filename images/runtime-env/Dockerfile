FROM maven:3.9.9-eclipse-temurin-17 as java-entrypoint
WORKDIR /root
COPY entrypoint ./
RUN mvn -T 1C package

FROM tomcat:9.0.95-jdk17-temurin-jammy
LABEL maintainer="Neoskop DevOps <devops@neoskop.de>"

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

# Prepare repositories cache
RUN mkdir -p /home/tomcat/magnolia_tmp/repositories && \
    chmod -R 0777 /home/tomcat/magnolia_tmp

# Prepare light modules dir
RUN mkdir -p /home/tomcat/light-modules

# Set workdir
WORKDIR /home/tomcat

# Expose port 8080 for http access and 5005 for debugging
EXPOSE 8080 5005

CMD ["/usr/local/bin/run.sh"]
VOLUME [ "/home/tomcat/magnolia_tmp", "/home/tomcat/magnolia_datastore" ]