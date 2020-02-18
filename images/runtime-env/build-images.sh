#!/bin/bash
set -e

JDK_VERSION=13
TOMCAT_MIN_VERSION=9.0.30
IMAGE_NAME=neoskop/mgnl-runtime-env

usage() {
    echo "usage: $0 [-hpkdv]"
    echo "  -h|--help      Display this text"
    echo "  -p|--push      Push the built images to the Docker Hub"
    echo "  -d|--dry-run   Only print commands that would be used to build images"
    echo "  -v|--verbose   Enable debug output"
    echo "  -f|--force     Push images regardless if they exist or not"
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
  get_tags $1 | grep -q "^$2$"
}

get_tags() {
  i=0
  has_more=""
  while [[ $has_more != "null" ]]; do
    i=$((i + 1))
    answer=$(curl -s "https://hub.docker.com/v2/repositories/$1/tags/?page_size=100&page=$i")
    result=$(echo "$answer" | jq -r '.results | map(.name) | .[]')
    has_more=$(echo "$answer" | jq -r '.next')
    if [[ ! -z "${result// /}" ]]; then results="${results}\n${result}"; fi
  done
  echo -e "$results"
}

get_relevant_tomcat_tags() {  
  local all_tags=$(get_tags library/tomcat | grep -E "^[0-9]+\.[0-9]+\.[0-9]+-jdk$JDK_VERSION-openjdk-oracle$" | sort -V)

  for tag in $(echo "$all_tags"); do 
    if [ "$TOMCAT_MIN_VERSION" = "`echo -e "$TOMCAT_MIN_VERSION\n$tag" | sort -V | head -n1`" ] ; then 
      echo "$tag"
    fi    
  done
}

build_image() {
   dockerfile=$(sed "s/^FROM tomcat:.*$/FROM tomcat:$1/" Dockerfile)

  if [ "$VERBOSE" == "YES" ]; then
    echo "Building $(bold $IMAGE_NAME:$2)"
  fi

  DOCKER_COMMAND="echo '$dockerfile' | docker build -t $IMAGE_NAME:$2 build -f-"

  if [ "$DRY_RUN" == "YES" ]; then
    echo "$DOCKER_COMMAND"

    if [ "$PUSH" == "YES" ]; then
      echo "docker push $IMAGE_NAME:$2"
    fi
  else
    eval "$DOCKER_COMMAND"

    if [ "$PUSH" == "YES" ]; then
      docker push $IMAGE_NAME:$2
    fi
  fi
}

for i in "$@"
do
case $i in
    -p|--push)
    PUSH=YES
    ;;
    -d|--dry-run)
    DRY_RUN=YES
    ;;
    -v|--verbose)
    VERBOSE=YES
    ;;
    -f | --force)
    FORCE=YES
    ;;
    -h|--help)
    usage $0
    ;;
    *)
    ;;
esac
done

for tomcat_tag in $(get_relevant_tomcat_tags); do
  app_tag=$(echo $tomcat_tag | grep -Po "^[0-9]+\.[0-9]+\.[0-9]+(?=-jdk$JDK_VERSION)")
    
  if [ "$FORCE" != "YES" ] && docker_tag_exists $IMAGE_NAME $app_tag ; then
    info "Ignoring $(bold $app_tag) since it already exists."
  else
    build_image "$tomcat_tag" "$app_tag"
  fi
done
