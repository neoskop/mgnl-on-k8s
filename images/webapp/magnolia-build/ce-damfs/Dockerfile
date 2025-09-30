FROM busybox:1.37.0-musl
ARG VERSION
COPY --chown=1000 ./ce-damfs/webapp-${VERSION}.war /ROOT.war
RUN mkdir -p /usr/local/tomcat/webapps && \
    chown 1000:1000 /usr/local/tomcat/webapps
VOLUME [ "/usr/local/tomcat/webapps" ]
CMD [ "sh", "-c", "mv /ROOT.war /usr/local/tomcat/webapps" ]