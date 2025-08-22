#!/usr/bin/env bash

source ./utils.sh

AIR_VERSION=${VERSION:-"latest"}
GITHUB_REPO=https://github.com/air-verse/air/

# Exit immediately if a command exits with a non-zero status.
set -e

export DEBIAN_FRONTEND=noninteractive

version_list=$(git ls-remote --tags ${GITHUB_REPO})

versions=($(find_latest_versions $AIR_VERSION version_list "tags/v"))
if [ $? -eq 1 ]; then
    echo "Can't find appropriate version"
    exit 1
fi

latest_version=${versions[0]}
prev_version=${versions[1]}

echo "Downloading air v${latest_version}...."

set +e

go install github.com/air-verse/air@v${latest_version}
exit_code=$?

set -e

if [ "$exit_code" != "0" ]; then
    # Handle situation where git tags are ahead of what was is available to actually download
    echo "(!) air version ${latest_version} failed to download. Attempting to fall back to ${prev_version} to retry..."
    go install github.com/air-verse/air@v${prev_version}
fi