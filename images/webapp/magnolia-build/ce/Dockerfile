FROM scratch
FROM maven:3.6.3-jdk-13 as build
ARG NEXUS_USERNAME
ARG NEXUS_PASSWORD
ARG MAGNOLIA_VERSION=6.1
ARG PAPERBOY_VERSION=2.3.3
COPY --from=neoskop/mgnl-deps:6.1 /root/.m2 /root/.m2
COPY ce/pom.parent.xml ./pom.xml
COPY ce/pom.webapp.xml ./webapp/pom.xml
RUN mvn \
    -DmagnoliaBundleVersion=$MAGNOLIA_VERSION \
    -DpaperboyVersion=$PAPERBOY_VERSION \
    -T 1 \
    compile
RUN mkdir -p ./webapp/src/main/webapp/WEB-INF
COPY WEB-INF ./webapp/src/main/webapp/WEB-INF
RUN mvn \
    -DmagnoliaBundleVersion=$MAGNOLIA_VERSION \
    -DpaperboyVersion=$PAPERBOY_VERSION \
    -T 1 \
    package

FROM busybox:1.31.1-musl
COPY --from=build --chown=1000 /webapp/target/webapp.war /ROOT.war
RUN mkdir -p /usr/local/tomcat/webapps && \
    chown 1000:1000 /usr/local/tomcat/webapps
VOLUME [ "/usr/local/tomcat/webapps" ]
CMD [ "sh", "-c", "mv /ROOT.war /usr/local/tomcat/webapps" ]