#!/usr/bin/env bash

set -e

check_commands() {
  for command in $@; do
    if ! command -v $command >/dev/null; then
      echo -e "Install \033[1m$command\033[0m"
      exit 1
    fi
  done
}

inc_version() {
  version=$1
  version_array=(${version//./ })

  if [ $2 = "major" ]; then
    ((version_array[0]++))
    version_array[1]=0
    version_array[2]=0
  fi

  if [ $2 = "minor" ]; then
    ((version_array[1]++))
    version_array[2]=0
  fi

  if [ $2 = "patch" ]; then
    ((version_array[2]++))
  fi

  echo "${version_array[0]}.${version_array[1]}.${version_array[2]}"
}

check_commands git jq yq cr

if [[ "$#" != "1" ]] || [[ ! "$1" =~ ^(patch|minor|major)$ ]]; then
  echo -e "Usage: $0 \033[1mpatch|minor|major\033[0m"
  exit 1
fi

if [[ $(git status --porcelain) ]]; then
  echo -e "The repository has changes. Commit first...\033[0;31mAborting!\033[0m"
  exit 1
fi

SCRIPT_DIR=$(
  cd "$(dirname "$0")" >/dev/null 2>&1
  pwd -P
)

git pull --rebase
current_version=$(yq eval .version $SCRIPT_DIR/../helm/Chart.yaml)
version=$(inc_version $current_version $1)
sed -i "s/appVersion: .*/appVersion: \"$version\"/" $SCRIPT_DIR/../helm/Chart.yaml
sed -i "s/version: .*/version: $version/" $SCRIPT_DIR/../helm/Chart.yaml
yq eval ".version=\"$version\"" -i $SCRIPT_DIR/../helm/Chart.yaml
yq eval ".appVersion=\"$version\"" -i $SCRIPT_DIR/../helm/Chart.yaml
yq eval ".magnoliaLightModuleUpdater.image.tag=\"$version\"" -i $SCRIPT_DIR/../helm/values.yaml
git add .
git commit -m "chore: Bump version to ${version}."
git push

helm package helm --destination .deploy
cr upload -o neoskop -r mgnl-on-k8s -p .deploy
git checkout gh-pages
cr index -i ./index.yaml -p .deploy -o neoskop -r mgnl-on-k8s -c https://neoskop.github.io/mgnl-on-k8s/
git add index.yaml
git commit -m "chore: Bump version to ${version}."
git push
git checkout master
rm -rf .deploy/

HELM_CHARTS_DIR=../neoskop-helm-charts
[ -d $HELM_CHARTS_DIR ] || git clone git@github.com:neoskop/helm-charts.git $HELM_CHARTS_DIR
cd $HELM_CHARTS_DIR
./update-index.sh
cd - &>/dev/null
