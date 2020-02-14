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
  rsync -r --exclude=.git --exclude=mtk $SOURCE_DIR/* $TARGET_DIR &>/dev/null
}

executed_without_error() {
  STDERR_OUTPUT=$($@ 2>&1 >/dev/null)

  if [ $? -ne 0 ]; then
    warn "Executing $(bold "$@") failed: \n\n$STDERR_OUTPUT\n"
    false
  fi
}

if [ -z "$GIT_REPO_URL" ] || [ -z "$GIT_PRIVATE_KEY" ] || [ -z "$SOURCE_DIR" ]; then
  echo "Specify $(bold \$GIT_REPO_URL), $(bold \$GIT_PRIVATE_KEY) and $(bold \$SOURCE_DIR)!"
  exit 1
fi

if ! [ -f ~/.ssh/id_rsa ]; then
  info "Writing private key to to $(bold ~/.ssh/id_rsa)"
  echo "$GIT_PRIVATE_KEY" >~/.ssh/id_rsa
fi

chmod 0600 ~/.ssh/id_rsa

if ! [ -d $REPO_DIR/.git ]; then
  info "Cloning $(bold $GIT_REPO_URL) to $(bold $REPO_DIR)"
  TEMP_DIR=$(mktemp -d)
  git clone -b $GIT_BRANCH $GIT_REPO_URL $TEMP_DIR/repo &>/dev/null
  cd $TEMP_DIR/repo
  rsync -ra . $REPO_DIR &>/dev/null
  cd - &>/dev/null
  rm -rf $TEMP_DIR
fi

cd $REPO_DIR

if [ -z "$(ls $TARGET_DIR)" ]; then
  info "Copying modules initially"
  copy_modules
fi

info "Starting to check repository for changes..."

while true; do
  if executed_without_error "git fetch"; then
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u})

    if [ $LOCAL != $REMOTE ]; then
      info "Pulling changes"

      if executed_without_error "git pull origin $GIT_BRANCH"; then
        copy_modules
      fi
    fi
  fi

  sleep $GIT_POLL_INTERVAL
done
