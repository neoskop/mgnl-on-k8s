#!/bin/bash
set -e

usage() {
  echo "usage: $0 [-hj]"
  echo "  -h|--help      Display this text"
  echo "  -j|--json      JSON output"
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

check_commands() {
  for command in $@; do
    if ! command -v $command >/dev/null; then
      echo -e "Install $(bold $command)"
      exit 1
    fi
  done
}

for i in "$@"; do
  case $i in
  -j | --json)
    JSON=YES
    ;;
  -h | --help)
    usage $0
    ;;
  *) ;;

  esac
done

check_commands openssl xxd tr

if [ "$JSON" != "YES" ]; then
  info "Generating an RSA key pair ready to be used for Magnolia activation..."
fi

TEMP_DIR=$(mktemp -d)
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:1024 -pkeyopt rsa_keygen_pubexp:65537 2>/dev/null |
  openssl pkcs8 -topk8 -nocrypt -outform der >$TEMP_DIR/private-key.p8 && cat $TEMP_DIR/private-key.p8 |
  xxd -plain |
  tr -d '\n' >$TEMP_DIR/private-key.p8.hex
openssl pkey -pubout -inform der -outform der -in $TEMP_DIR/private-key.p8 -out $TEMP_DIR/public-key.spki
cat $TEMP_DIR/public-key.spki |
  xxd -plain |
  tr -d '\n' >$TEMP_DIR/public-key.spki.hex

PRIVATE_KEY=$(cat $TEMP_DIR/private-key.p8.hex)
PUBLIC_KEY=$(cat $TEMP_DIR/public-key.spki.hex)

if [ "$JSON" != "YES" ]; then
  info "$(bold 'Private key:') $PRIVATE_KEY"
  info "$(bold 'Public key:') $PUBLIC_KEY"
else
  echo "{\"privateKey\":\"$PRIVATE_KEY\",\"publicKey\":\"$PUBLIC_KEY\"}"
fi

rm -rf $TEMP_DIR
