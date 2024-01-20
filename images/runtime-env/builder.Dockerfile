FROM docker:25.0
ARG DOCKERHUB_USERNAME
ARG DOCKERHUB_PASSWORD
RUN test -n "$DOCKERHUB_USERNAME" && \
    test -n "$DOCKERHUB_PASSWORD" && \
    apk add --no-cache wget jq curl bash grep && \
    mkdir -p ~/.docker/ && \
    echo "$DOCKERHUB_PASSWORD" | docker login --username $DOCKERHUB_USERNAME --password-stdin
WORKDIR /workspace
COPY . ./
CMD [ "./build-images.sh", "-p", "-f" ]