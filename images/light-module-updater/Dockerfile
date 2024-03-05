FROM ubuntu:24.04
ENV GIT_BRANCH=master \
    CHECKOUT_TAG=false \
    POLL_INTERVAL=5 \
    REPO_DIR=/home/docker/repo \
    TARGET_DIR="/home/tomcat/light-modules"
RUN apt-get update -qq && \
    apt-get install -qq -y software-properties-common && \
    add-apt-repository -y ppa:git-core/ppa && \
    apt-get update -qq && \
    apt-get install -qq -y git openssh-client rsync && \
    id "1000" ||useradd -m --uid 1000 ubuntu && \
    mkdir -p "$TARGET_DIR" && \
    chown docker "$TARGET_DIR" && \
    mkdir -p "$REPO_DIR" && \
    chown docker "$REPO_DIR" && \
    rm -rf /var/lib/apt/lists/*
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