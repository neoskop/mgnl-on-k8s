#!/bin/sh
set -e

usage() {
    echo "usage: $0 [-hpkdv]"
    echo "  -h|--help      Display this text"
    echo "  -p|--push      Push the built images to the Docker Hub"
    echo "  -k|--kaniko    Use Kaniko to build and push the image"
    echo "  -d|--dry-run   Only print commands that would be used to build images"
    echo "  -v|--verbose   Enable debug output"
    exit 1
}

bold() {
  local BOLD='\033[1m'
  local NC='\033[0m'
  printf "${BOLD}${1}${NC}"
}

info() {
  local BLUE='\033[1;34m'
  local NC='\033[0m'
  printf "[${BLUE}INFO${NC}] $1\n"
}

error() {
  local RED='\033[1;31m'
  local NC='\033[0m'
  printf "[${RED}ERROR${NC}] $1\n"
}

warn() {
  local ORANGE='\033[1;33m'
  local NC='\033[0m'
  printf "[${ORANGE}WARN${NC}] $1\n"
}

docker_tag_exists() {
    TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${DOCKERHUB_USERNAME}'", "password": "'${DOCKERHUB_PASSWORD}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)
    EXISTS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/$1/tags/?page_size=10000 | jq -r "[.results | .[] | .name == \"$2\"] | any")
    test "$EXISTS" = true
}

get_tomcat_tags() {
  local all_tags=$( \
    wget -q https://registry.hub.docker.com/v1/repositories/tomcat/tags -O - | \
    sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | \
    tr '}' '\n'  | \
    awk -F: '{print $3}' | \
    grep -E '[0-9]+\.[0-9]+\.[0-9]+-jdk[0-9]+-openjdk-' | \
    sort -V
  )
  local min_version="8.5.47"

  for tag in $(echo "$all_tags"); do 
    if [ "$min_version" = "`echo -e "$min_version\n$tag" | sort -V | head -n1`" ] ; then 
      echo "$tag"
    fi    
  done
}

build_image() {
   dockerfile=$(sed "s/^FROM tomcat:.*$/FROM tomcat:$1/" dockerfiles/$2/Dockerfile)

  if [ "$VERBOSE" == "YES" ]; then
    echo "Building $3"
  fi

  if [ "$KANIKO" == "YES" ]; then
    TEMP_FILE=$(mktemp)
    echo "$dockerfile" > $TEMP_FILE
    KANIKO_COMMAND="executor \
      --destination $3 \
      --dockerfile $TEMP_FILE \
      --context . \
      --single-snapshot"

    if [ "$PUSH" != "YES" ]; then
      KANIKO_COMMAND="$KANIKO_COMMAND --no-push"
    fi

    if [ "$DRY_RUN" == "YES" ]; then
      echo "$KANIKO_COMMAND"
    else
      eval "$KANIKO_COMMAND"
    fi

    rm -rf "$TEMP_FILE"
  else
    DOCKER_COMMAND="echo '$dockerfile' | docker build -t $3 build -f-"

    if [ "$DRY_RUN" == "YES" ]; then
      echo "$DOCKER_COMMAND"

      if [ "$PUSH" == "YES" ]; then
        echo "docker push $3"
      fi
    else
      eval "$DOCKER_COMMAND"

      if [ "$PUSH" == "YES" ]; then
        docker push $3
      fi
    fi
  fi
}

for i in "$@"
do
case $i in
    -p|--push)
    PUSH=YES
    ;;
    -k|--kaniko)
    KANIKO=YES
    ;;
    -d|--dry-run)
    DRY_RUN=YES
    ;;
    -v|--verbose)
    VERBOSE=YES
    ;;
    -h|--help)
    usage $0
    ;;
    *)
    ;;
esac
done

for tag in `get_tomcat_tags`; do
  variant=slim

  if echo "$tag" | grep -q oracle$ ; then
      variant=oracle
  fi

  image_name=neoskop/mgnl-runtime-env:$tag
    
  if docker_tag_exists neoskop/mgnl-runtime-env $tag ; then
    info "Ignoring $(bold $image_name) since it already exists."
  else
    build_image "$tag" "$variant" "$image_name"
  fi
done
