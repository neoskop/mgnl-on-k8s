FROM alpine:3.13.0
ENV GIT_BRANCH=master \
    CHECKOUT_TAG=false \
    POLL_INTERVAL=5 \
    REPO_DIR=/home/docker/repo \
    TARGET_DIR="/home/tomcat/light-modules"
RUN apk add --no-cache git openssh-client rsync && \
    adduser -S --uid 1000 docker && \
    mkdir -p $TARGET_DIR && \
    chown docker $TARGET_DIR && \
    mkdir -p $REPO_DIR && \
    chown docker $REPO_DIR
USER docker
WORKDIR /home/docker
ARG GIT_HOSTS="bitbucket.org github.com"
RUN mkdir -p ~/.ssh && \
    for host in $GIT_HOSTS ; do \
    ssh-keyscan "$host" >> ~/.ssh/known_hosts ; \
    done
COPY docker-entrypoint.sh /
VOLUME ["$TARGET_DIR", "/home/docker/repo"]
CMD ["/docker-entrypoint.sh"]