#!/bin/bash
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
  TEMP_DIR=$(mktemp -d)
  rsync \
    -r \
    --exclude=.git \
    --exclude=mtk \
    --temp-dir=$TEMP_DIR \
    $SOURCE_DIR/* \
    $TARGET_DIR \
    --delete \
    &>/dev/null
  rm -rf $TEMP_DIR
}

executed_without_error() {
  STDERR_OUTPUT=$($@ 2>&1 >/dev/null)

  if [ $? -ne 0 ]; then
    warn "Executing $(bold "$@") failed: \n\n$STDERR_OUTPUT\n"
    false
  fi
}

update_tag() {
  TAG_FILE_PATH='/home/docker/config/tag'

  if [ -f $TAG_FILE_PATH ]; then
    GIT_OLD_TAG=$GIT_TAG
    GIT_TAG=$(cat $TAG_FILE_PATH)
    [ "$GIT_TAG" != "$GIT_OLD_TAG" ]
  else
    return 1
  fi
}

clone_repo() {
  info "Cloning $(bold $GIT_REPO_URL) to $(bold $REPO_DIR)"
  git init &>/dev/null

  if ! executed_without_error "git remote add -f origin $GIT_REPO_URL"; then
    error "Setting up upstream failed ... Exiting."
    exit 1
  fi

  git config core.sparseCheckout true
  echo "$SOURCE_DIR" >>.git/info/sparse-checkout

  if ! executed_without_error "git pull origin $GIT_BRANCH && git checkout $GIT_BRANCH"; then
    error "Initial clone failed ... Exiting."
    exit 1
  fi

  if [ -n "$GIT_TAG" ]; then
    info "Checking out tag $(bold $GIT_TAG)"
    git -c advice.detachedHead=false checkout tags/$GIT_TAG &>/dev/null
  fi
}

clone_from_scratch() {
  cd $HOME &>/dev/null
  rm -rf $REPO_DIR &>/dev/null
  mkdir -p $REPO_DIR &>/dev/null
  cd $REPO_DIR &>/dev/null
  clone_repo
  copy_modules
}

if [ -z "$GIT_REPO_URL" ] || [ -z "$GIT_PRIVATE_KEY" ] || [ -z "$SOURCE_DIR" ]; then
  error "Specify $(bold \$GIT_REPO_URL), $(bold \$GIT_PRIVATE_KEY) and $(bold \$SOURCE_DIR)!"
  exit 1
fi

if [ -f "/sys/fs/cgroup/memory.max" ]; then
  mem_file=/sys/fs/cgroup/memory.max
else
  mem_file=/sys/fs/cgroup/memory/memory.limit_in_bytes
fi

MEMORY_LIMIT=$(expr $(cat $mem_file) / 1024 / 1024)
info "Configuring Git for memory limit of $(bold "${MEMORY_LIMIT} MiB")"
git config --global core.packedGitWindowSize $(expr $MEMORY_LIMIT / 10)m
git config --global core.packedGitLimit $(expr $MEMORY_LIMIT / 2)m
git config --global pack.deltaCacheSize $(expr $MEMORY_LIMIT / 4)m
git config --global pack.packSizeLimit $(expr $MEMORY_LIMIT / 4)m
git config --global pack.windowMemory $(expr $MEMORY_LIMIT / 4)m
git config --global pack.threads 1
git config --global pull.ff only

if ! [ -f ~/.ssh/id_rsa ]; then
  info "Writing private key to to $(bold ~/.ssh/id_rsa)"
  echo -e "$GIT_PRIVATE_KEY" >~/.ssh/id_rsa
fi

chmod 0600 ~/.ssh/id_rsa

if [ "$CHECKOUT_TAG" == "true" ]; then
  update_tag || warn "$(bold CHECKOUT_TAG) is true, yet no tag is specified"
fi

cd $REPO_DIR

if ! [ -d .git ]; then
  clone_repo
fi

info "Copying modules initially"
copy_modules

if [ "$CHECKOUT_TAG" == "true" ]; then
  info "Starting to check tag config file ($(bold ~/config/tag)) for changes..."
else
  info "Starting to check repository for changes..."
fi

while true; do
  if [ "$CHECKOUT_TAG" == "true" ]; then
    if update_tag; then
      if [ -z "$GIT_OLD_TAG" ]; then
        info "Tag was set to $(bold $GIT_TAG). Fetching and checking out tag"
      else
        info "Tag was changed from $(bold $GIT_OLD_TAG) to $(bold $GIT_TAG). Fetching and checking out tag"
      fi

      if executed_without_error "git fetch" && executed_without_error "git -c advice.detachedHead=false checkout tags/$GIT_TAG"; then
        copy_modules
      fi
    fi
  else
    if executed_without_error "git fetch"; then
      LOCAL=$(git rev-parse HEAD)
      REMOTE=$(git rev-parse origin/$GIT_BRANCH)

      if [ $LOCAL != $REMOTE ]; then
        info "Pulling changes"

        if executed_without_error "git pull origin $GIT_BRANCH"; then
          copy_modules
        else
          warn "$(bold git pull origin $GIT_BRANCH) failed ... will try to clone from scratch"
          clone_from_scratch
        fi
      fi
    else
      warn "$(bold git fetch) failed ... will try to clone from scratch"
      clone_from_scratch
    fi
  fi

  sleep $POLL_INTERVAL
done
