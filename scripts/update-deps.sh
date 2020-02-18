#!/bin/bash
set -e

JDK_VERSION=13

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

check_commands() {
  for command in $@; do
    if ! command -v $command >/dev/null; then
      echo -e "Install $(bold $command)"
      exit 1
    fi
  done
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

check_commands jq yq
echo "Will use the following new image versions:"
MVN_LATEST_TAG=$(get_tags library/maven | grep -E "^[0-9]+\.[0-9]+\.[0-9]+-jdk-$JDK_VERSION$" | sort -V | tail -n 1)
echo "  - Maven: $(bold $MVN_LATEST_TAG)"
MAGNOLIA_LATEST_TAG=$(get_tags neoskop/mgnl-webapp-ce | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | sort -V | tail -n 1)
echo "  - Magnolia Webapp CE: $(bold $MAGNOLIA_LATEST_TAG)"
MAGNOLIA_RUNTIME_ENV_LATEST_TAG=$(get_tags neoskop/mgnl-runtime-env | grep '^[0-9]*\.[0-9]*\.[0-9]*-jdk[0-9]*' | sort -V | tail -n 1)
echo "  - Magnolia Runtime environment: $(bold $MAGNOLIA_RUNTIME_ENV_LATEST_TAG)"
MYSQL_LATEST_TAG=$(get_tags library/mysql | grep '^5.7' | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | sort -V | tail -n 1)
echo "  - MySQL: $(bold $MYSQL_LATEST_TAG)"
BUSYBOX_LATEST_TAG=$(get_tags library/busybox | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | sort -V | tail -n 1)
echo "  - Busybox: $(bold $BUSYBOX_LATEST_TAG)"
ALPINE_LATEST_TAG=$(get_tags library/alpine | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | sort -V | tail -n 1)
echo "  - Alpine: $(bold $ALPINE_LATEST_TAG)"
yq w -i helm/values.yaml magnoliaWebapp.image.tag $MAGNOLIA_LATEST_TAG
yq w -i helm/values.yaml magnoliaRuntime.image.tag $MAGNOLIA_RUNTIME_ENV_LATEST_TAG
yq w -i helm/values.yaml mysql.image.tag $MYSQL_LATEST_TAG
yq w -i helm/values.yaml tmpInit.image.tag $BUSYBOX_LATEST_TAG
yq w -i helm/values.yaml mysqlInit.image.tag $BUSYBOX_LATEST_TAG
sed -i "s/^FROM maven:.* as java-entrypoint$/FROM maven:$MVN_LATEST_TAG as java-entrypoint/" images/runtime-env/Dockerfile
sed -i "s/^FROM alpine:.*$/FROM alpine:$ALPINE_LATEST_TAG/" images/light-module-updater/Dockerfile