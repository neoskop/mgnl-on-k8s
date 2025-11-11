FROM docker:29.0
ARG DOCKERHUB_USERNAME
ARG DOCKERHUB_PASSWORD
RUN test -n "NEXUS_USERNAME" && \
    test -n "NEXUS_PASSWORD" && \
    test -n "$DOCKERHUB_USERNAME" && \
    test -n "$DOCKERHUB_PASSWORD" && \
    apk add --no-cache xmlstarlet jq curl && \
    mkdir -p ~/.docker/ && \
    echo "$DOCKERHUB_PASSWORD" | docker login --username $DOCKERHUB_USERNAME --password-stdin
WORKDIR /workspace
COPY magnolia-build ./magnolia-build
COPY build-images.sh ./build-images.sh
CMD [ "./build-images.sh", "-p" ]