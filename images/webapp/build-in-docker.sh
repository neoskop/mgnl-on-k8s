#!/bin/bash
set -e
DOCKERHUB_AUTH=$(echo "$DOCKERHUB_USERNAME:$DOCKERHUB_PASSWORD" | base64)
docker build \
       -f Dockerfile.builder \
       --build-arg DOCKERHUB_USERNAME=$DOCKERHUB_USERNAME \
       --build-arg DOCKERHUB_PASSWORD=$DOCKERHUB_PASSWORD \
       -t neoskop/mgnl-webapp-builder \
       .
docker run \
       --rm \
       --privileged \
       --name mgnl-webapp-builder \
       -v /var/run/docker.sock:/var/run/docker.sock \
       -e NEXUS_USERNAME=$NEXUS_USERNAME \
       -e NEXUS_PASSWORD=$NEXUS_PASSWORD \
       -e DOCKERHUB_USERNAME=$DOCKERHUB_USERNAME \
       -e DOCKERHUB_PASSWORD=$DOCKERHUB_PASSWORD \
       neoskop/mgnl-webapp-builder
docker system prune -a -f