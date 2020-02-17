#!/bin/bash
set -e

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
  curl -s https://hub.docker.com/v2/repositories/$1/tags/?page_size=10000 | jq -r '.results | map(.name) | .[]'
}

check_commands jq yq
echo "Will use the following new image versions:"
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
sed -i "s/^FROM alpine:.*$/FROM alpine:$ALPINE_LATEST_TAG/" images/light-module-updater/Dockerfile