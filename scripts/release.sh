#!/usr/bin/env bash

set -e

if [[ "$#" != "1" ]] || [[ ! "$1" =~ ^(patch|minor|major)$ ]]; then
  echo -e "Usage: $0 \033[1mpatch|minor|major\033[0m"
  exit 1
fi

if ! command -v gh >/dev/null; then
  echo -e "Install \033[1mgh\033[0m (GitHub CLI)"
  exit 1
fi

echo "Triggering release workflow with bump type: $1"
gh workflow run release.yml -f bump="$1"

echo ""
echo "Release workflow triggered. Monitor at:"
echo "  https://github.com/neoskop/mgnl-on-k8s/actions/workflows/release.yml"
