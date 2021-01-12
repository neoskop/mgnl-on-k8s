#!/bin/ash
set -e

bold() {
  local BOLD='\033[1m'
  local NC='\033[0m'
  printf "${BOLD}${@}${NC}"
}

info() {
  local BLUE='\033[1;34m'
  local NC='\033[0m'
  printf "[${BLUE}INFO${NC}] $@\n"
}

error() {
  local RED='\033[1;31m'
  local NC='\033[0m'
  printf "[${RED}ERROR${NC}] $@\n"
}

warn() {
  local ORANGE='\033[1;33m'
  local NC='\033[0m'
  printf "[${ORANGE}WARN${NC}] $@\n"
}

copy_modules() {
  info "Copying $(bold $SOURCE_DIR) to $(bold $TARGET_DIR)"
  rsync -r --exclude=.git --exclude=mtk $SOURCE_DIR/* $TARGET_DIR --delete &>/dev/null
}

executed_without_error() {
  STDERR_OUTPUT=$($@ 2>&1 >/dev/null)

  if [ $? -ne 0 ]; then
    warn "Executing $(bold "$@") failed: \n\n$STDERR_OUTPUT\n"
    false
  fi
}

update_tag() {
  TAG_FILE_PATH='/home/docker/config/tag';

  if [ -f $TAG_FILE_PATH ]; then
    GIT_OLD_TAG=$GIT_TAG
    GIT_TAG=$(cat $TAG_FILE_PATH)
    [ "$GIT_TAG" != "$GIT_OLD_TAG" ]
  else
    return 1
  fi
}

if [ -z "$GIT_REPO_URL" ] || [ -z "$GIT_PRIVATE_KEY" ] || [ -z "$SOURCE_DIR" ]; then
  error "Specify $(bold \$GIT_REPO_URL), $(bold \$GIT_PRIVATE_KEY) and $(bold \$SOURCE_DIR)!"
  exit 1
fi

if ! [ -f ~/.ssh/id_rsa ]; then
  info "Writing private key to to $(bold ~/.ssh/id_rsa)"
  echo "$GIT_PRIVATE_KEY" >~/.ssh/id_rsa
fi

chmod 0600 ~/.ssh/id_rsa

if [ "$CHECKOUT_TAG" == "true" ]; then
  update_tag || warn "$(bold CHECKOUT_TAG) is true, yet no tag is specified"
fi

if ! [ -d $REPO_DIR/.git ]; then
  info "Cloning $(bold $GIT_REPO_URL) to $(bold $REPO_DIR)"
  TEMP_DIR=$(mktemp -d)
  git clone -b $GIT_BRANCH $GIT_REPO_URL $TEMP_DIR/repo &>/dev/null
  cd $TEMP_DIR/repo

  if [ -n "$GIT_TAG" ]; then
    info "Checking out tag $(bold $GIT_TAG)"
    git -c advice.detachedHead=false checkout tags/$GIT_TAG &>/dev/null
  fi

  rsync -ra . $REPO_DIR --delete &>/dev/null
  cd - &>/dev/null
  rm -rf $TEMP_DIR
fi

cd $REPO_DIR
info "Copying modules initially"
copy_modules

if [ "$CHECKOUT_TAG" == "true" ]; then
  info "Starting to check tag config file ($(bold ~/config/tag)) for changes..."
else
  info "Starting to check repository for changes..."
fi

while true; do
  if [ "$CHECKOUT_TAG" == "true" ]; then
    if update_tag ; then 
      if [ -z "$GIT_OLD_TAG" ]; then
        info "Tag was set to $(bold $GIT_TAG). Fetching and checking out tag"
      else
        info "Tag was changed from $(bold $GIT_OLD_TAG) to $(bold $GIT_TAG). Fetching and checking out tag"
      fi

      if executed_without_error "git fetch" && executed_without_error "git -c advice.detachedHead=false checkout tags/$GIT_TAG" ; then
        copy_modules
      fi
    fi
  elif executed_without_error "git fetch"; then
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u})

    if [ $LOCAL != $REMOTE ]; then
      info "Pulling changes"

      if executed_without_error "git pull origin $GIT_BRANCH"; then
        copy_modules
      fi
    fi
  fi

  sleep $POLL_INTERVAL
done
