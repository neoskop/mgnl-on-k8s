#!/bin/bash
set -e

usage() {
    echo "usage: $0 [-hk]"
    echo "  -h|--help      Display this text"
    echo "  -k|--key       Pass private SSH key automatically"
    exit 1
}

check_commands() {
    for command in $@; do
        if ! command -v $command >/dev/null; then
            echo -e "Install $(bold $command)"
            exit 1
        fi
    done
}

check_commands helm pwgen jq base64

for i in "$@"; do
    case $i in
    -k | --key)
        KEY=YES
        ;;
    -h | --help)
        usage $0
        ;;
    *) ;;

    esac
done

SCRIPT_DIR=$(
    cd "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)
ACTIVATION_KEYPAIR=$($SCRIPT_DIR/generate-activation-keypair.sh -j)
ACTIVATION_PRIVATE_KEY=$(echo "$ACTIVATION_KEYPAIR" | jq -r .privateKey)
ACTIVATION_PUBLIC_KEY=$(echo "$ACTIVATION_KEYPAIR" | jq -r .publicKey)

if [ -z "$NAMESPACE" ]; then
    NAMESPACE=mgnl-quickstart
fi

COMMAND=$(echo "helm upgrade --install \
    $NAMESPACE \
    $SCRIPT_DIR/../helm \
    -n $NAMESPACE \
    --set paperboy.userPassword=$(pwgen 32 1) \
    --set paperboy.token=$(pwgen 32 1) \
    --set paperboyPreview.userPassword=$(pwgen 32 1) \
    --set paperboyPreview.token=$(pwgen 32 1) \
    --set mysql.rootPassword=$(pwgen 32 1) \
    --set magnoliaActivation.privateKey=$ACTIVATION_PRIVATE_KEY \
    --set magnoliaActivation.publicKey=$ACTIVATION_PUBLIC_KEY")

if [ "$KEY" = "YES" ]; then
    COMMAND="$COMMAND --set magnoliaLightModuleUpdater.privateKey=$(cat $HOME/.ssh/id_rsa | base64 -w0)"
elif [ -n "$SSH_PRIVATE_KEY" ]; then
    COMMAND="$COMMAND --set magnoliaLightModuleUpdater.privateKey=$SSH_PRIVATE_KEY"
fi

if [ -n "$REPO_URL" ]; then
    COMMAND="$COMMAND --set magnoliaLightModuleUpdater.repoUrl=$REPO_URL"
fi

if [ -n "$SOURCE_DIR" ]; then
    COMMAND="$COMMAND --set magnoliaLightModuleUpdater.sourceDir=$SOURCE_DIR"
fi

if ! kubectl get ns $NAMESPACE &>/dev/null; then
    kubectl create ns $NAMESPACE
fi

exec $COMMAND
