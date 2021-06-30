FROM ubuntu:21.10
ENV GIT_BRANCH=master \
    CHECKOUT_TAG=false \
    POLL_INTERVAL=5 \
    REPO_DIR=/home/docker/repo \
    TARGET_DIR="/home/tomcat/light-modules"
RUN apt-get update -q && \
    apt-get install -q -y software-properties-common && \
    add-apt-repository -y ppa:git-core/ppa && \
    apt-get update -q && \
    apt-get install -q -y git openssh-client && \
    useradd -m --uid 1000 docker && \
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