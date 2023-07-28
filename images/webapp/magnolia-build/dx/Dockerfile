FROM scratch
FROM maven:3.6.3-jdk-13 as build
ARG NEXUS_USERNAME
ARG NEXUS_PASSWORD
ARG MAGNOLIA_VERSION=6.1
ARG PAPERBOY_VERSION=2.3.3
RUN test -n "$NEXUS_USERNAME" && \
    test -n "$NEXUS_PASSWORD"
COPY --from=neoskop/mgnl-deps:6.1 /root/.m2 /root/.m2
RUN echo "<settings><servers><server><id>magnolia.enterprise</id><username>$NEXUS_USERNAME</username><password>$NEXUS_PASSWORD</password></server><server><id>magnolia.enterprise.releases</id><username>$NEXUS_USERNAME</username><password>$NEXUS_PASSWORD</password></server></servers></settings>" > /mvn-settings.xml
COPY dx/pom.parent.xml ./pom.xml
COPY dx/pom.webapp.xml ./webapp/pom.xml
RUN mvn -s /mvn-settings.xml \
    -DmagnoliaBundleVersion=$MAGNOLIA_VERSION \
    -DpaperboyVersion=$PAPERBOY_VERSION \
    -T 1C \
    compile
RUN mkdir -p ./webapp/src/main/webapp/WEB-INF
COPY WEB-INF ./webapp/src/main/webapp/WEB-INF
RUN sed -i s/MagnoliaWidgetSet/MagnoliaProWidgetSet/ ./webapp/src/main/webapp/WEB-INF/config/default/magnolia.properties
RUN mvn -s /mvn-settings.xml \
    -DmagnoliaBundleVersion=$MAGNOLIA_VERSION \
    -DpaperboyVersion=$PAPERBOY_VERSION \
    -T 1C \
    package

FROM busybox:1.36.1-musl
COPY --from=build --chown=1000 /webapp/target/webapp.war /ROOT.war
RUN mkdir -p /usr/local/tomcat/webapps && \
    chown 1000:1000 /usr/local/tomcat/webapps
VOLUME [ "/usr/local/tomcat/webapps" ]
CMD [ "sh", "-c", "mv /ROOT.war /usr/local/tomcat/webapps" ]