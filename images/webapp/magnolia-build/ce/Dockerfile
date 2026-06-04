FROM busybox:1.37.0-musl@sha256:222ad6d973c0d198014546a65cd02c5fdedcc172123c5b4c2bf0af636550bd94
ARG VERSION
COPY --chown=1000 ./ce/webapp-${VERSION}.war /ROOT.war
RUN mkdir -p /usr/local/tomcat/webapps && \
    chown 1000:1000 /usr/local/tomcat/webapps
VOLUME [ "/usr/local/tomcat/webapps" ]
CMD [ "sh", "-c", "mv /ROOT.war /usr/local/tomcat/webapps" ]