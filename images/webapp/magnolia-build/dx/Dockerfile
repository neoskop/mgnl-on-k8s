FROM busybox:1.36.1-musl
ARG VERSION
COPY --chown=1000 ./dx/webapp-${VERSION}.war /ROOT.war
RUN mkdir -p /usr/local/tomcat/webapps && \
    chown 1000:1000 /usr/local/tomcat/webapps
VOLUME [ "/usr/local/tomcat/webapps" ]
CMD [ "sh", "-c", "mv /ROOT.war /usr/local/tomcat/webapps" ]