#!/bin/sh
set -e

usage() {
  echo "usage: $0 [-hpkdvf]"
  echo "  -h|--help      Display this text"
  echo "  -p|--push      Push the built images to the Docker Hub"
  echo "  -k|--kaniko    Use Kaniko to build and push the image"
  echo "  -d|--dry-run   Only print commands that would be used to build images"
  echo "  -v|--verbose   Enable debug output"
  echo "  -f|--force     Push images regardless if they exist or not"
  echo ""
  echo "environment varibles:"
  echo "  NEXUS_USERNAME:      your username for the Magnolia CMS Nexus. $(bold "Required.")"
  echo "  NEXUS_PASSWORD:      your password for the Magnolia CMS Nexus. $(bold "Required.")"
  echo "  DOCKERHUB_USERNAME:  your username for hub.docker.com. $(bold "Required.")"
  echo "  DOCKERHUB_PASSWORD:  your password for hub.docker.com. $(bold "Required.")"
  echo "  FLAVORS:             a space-separated list of flavors to build. Can be one $(bold "dx"), $(bold "dx-workflow") or $(bold "ce")."
  echo "  VERSION:             a space-separated list of versions to build (e.g. 6.2.2)."
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

get_available_magnolia_versions() {
  versions=$(
    curl -U "$NEXUS_USERNAME:$NEXUS_PASSWORD" "https://nexus.magnolia-cms.com/service/local/lucene/search?g=info.magnolia&a=magnolia-empty-webapp" 2>/dev/null |
      xmlstarlet sel -t -v '//artifact/version/text()' - |
      sort -r
  )

  for version in $versions; do
    MIN_VERSION="6.1"

    if [ "$(printf '%s\n' "$MIN_VERSION" "$version" | sort -V | head -n1)" = "$MIN_VERSION" ] &&
      echo "$version" | grep -vq "SNAPSHOT"; then
      echo "$version"
    fi
  done
}

docker_tag_exists() {
  TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${DOCKERHUB_USERNAME}'", "password": "'${DOCKERHUB_PASSWORD}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)
  EXISTS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/$1/tags/?page_size=10000 | jq -r "[.results | .[] | .name == \"$2\"] | any")
  test "$EXISTS" = true
}

build_image() {
  info "Building $(bold $image_name)"

  if [ "$KANIKO" = "YES" ]; then
    KANIKO_COMMAND="executor \
        --build-arg=MAGNOLIA_VERSION=$2 \
        --destination $3 \
        --dockerfile $(dirname $0)/magnolia-build/$1/Dockerfile \
        --context $(dirname $0)/magnolia-build \
        --single-snapshot"

    if [ -n "$NEXUS_USERNAME" ] && [ -n "$NEXUS_PASSWORD" ]; then
      KANIKO_COMMAND="$KANIKO_COMMAND \
        --build-arg=NEXUS_USERNAME=$NEXUS_USERNAME \
        --build-arg=NEXUS_PASSWORD=$NEXUS_PASSWORD"
    fi

    if [ "$PUSH" != "YES" ]; then
      KANIKO_COMMAND="$KANIKO_COMMAND --no-push"
    fi

    if [ "$DRY_RUN" = "YES" ]; then
      info "$KANIKO_COMMAND"
    else
      eval "$KANIKO_COMMAND"
    fi
  else
    BUILD_COMMAND="docker build \
      --build-arg MAGNOLIA_VERSION=$2 \
      -t $3 \
      -f $(dirname $0)/magnolia-build/$1/Dockerfile"

    if [ -n "$NEXUS_USERNAME" ] && [ -n "$NEXUS_PASSWORD" ]; then
      BUILD_COMMAND="$BUILD_COMMAND \
      --build-arg NEXUS_USERNAME=$NEXUS_USERNAME \
      --build-arg NEXUS_PASSWORD=$NEXUS_PASSWORD"
    fi

    BUILD_COMMAND="$BUILD_COMMAND \
      $(dirname $0)/magnolia-build"

    if [ "$DRY_RUN" = "YES" ]; then
      info "$BUILD_COMMAND"

      if [ "$PUSH" = "YES" ]; then
        info "docker push $3"
      fi
    else
      eval "$BUILD_COMMAND"

      if [ "$PUSH" = "YES" ]; then
        docker push $3
      fi
    fi
  fi
}

for i in "$@"; do
  case $i in
  -p | --push)
    PUSH=YES
    ;;
  -k | --kaniko)
    KANIKO=YES
    ;;
  -d | --dry-run)
    DRY_RUN=YES
    ;;
  -v | --verbose)
    VERBOSE=YES
    ;;
  -f | --force)
    FORCE=YES
    ;;
  -h | --help)
    usage $0
    ;;
  *) ;;

  esac
done

if ! (command -v xmlstarlet 2>&1 >/dev/null) || ! (command -v curl 2>&1 >/dev/null) || ! (command -v jq 2>&1 >/dev/null); then
  error "Make sure $(bold xmlstarlet), $(bold curl) and  $(bold jq) are installed."
  exit 1
fi

if [ -z $NEXUS_USERNAME ] || [ -z $NEXUS_PASSWORD ]; then
  error "Provide $(bold NEXUS_USERNAME) and $(bold NEXUS_PASSWORD)"
  exit 1
fi

if [ -z $DOCKERHUB_USERNAME ] || [ -z $DOCKERHUB_PASSWORD ]; then
  error "Provide $(bold DOCKERHUB_USERNAME) and $(bold DOCKERHUB_PASSWORD)"
  exit 1
fi

if [ -z $FLAVORS ]; then
  FLAVORS=ce,dx,dx-workflow
fi

FLAVORS=$(echo "$FLAVORS" | tr ',' ' ')

if [ -z $VERSIONS ]; then
  VERSIONS=$(get_available_magnolia_versions)
else
  VERSIONS=$(echo "$VERSIONS" | tr ',' ' ')
fi

for version in $VERSIONS; do
  for flavor in $FLAVORS; do
    image_name=neoskop/mgnl-webapp-$flavor:$version

    if [ "$FORCE" != "YES" ] && docker_tag_exists neoskop/mgnl-webapp-$flavor $version; then
      info "Ignoring $(bold $image_name) since it already exists."
    else
      build_image "$flavor" "$version" "$image_name"
    fi
  done
done
