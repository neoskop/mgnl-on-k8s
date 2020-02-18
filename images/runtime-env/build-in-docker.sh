#!/bin/bash
set -e
docker build \
       -f builder.Dockerfile \
       --build-arg DOCKERHUB_USERNAME=$DOCKERHUB_USERNAME \
       --build-arg DOCKERHUB_PASSWORD=$DOCKERHUB_PASSWORD \
       -t neoskop/mgnl-runtime-env-builder \
       .
docker run \
       --rm \
       --privileged \
       --name mgnl-runtime-env-builder \
       -v /var/run/docker.sock:/var/run/docker.sock \
       -e DOCKERHUB_USERNAME=$DOCKERHUB_USERNAME \
       -e DOCKERHUB_PASSWORD=$DOCKERHUB_PASSWORD \
       neoskop/mgnl-runtime-env-builder
docker system prune -a -f