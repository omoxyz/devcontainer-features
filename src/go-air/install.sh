#!/usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Scripts must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

source ./utils.sh

AIR_VERSION=${VERSION:-"latest"}
INSTALL_DIRECTLY_FROM_GITHUB_RELEASE=${INSTALLDIRECTLYFROMGITHUBRELEASE:-"true"}
GITHUB_REPO=https://github.com/air-verse/air/

# Exit immediately if a command exits with a non-zero status.
set -e

apt_get_update

# Clean up
rm -rf /var/lib/apt/lists/*

export DEBIAN_FRONTEND=noninteractive

install_using_go() {
    local latest_version=$1
    local prev_version=$2

    set +e

    go install github.com/air-verse/air@v${latest_version}
    exit_code=$?

    set -e

    if [ "$exit_code" != "0" ]; then
        # Handle situation where git tags are ahead of what was is available to actually download
        echo "(!) air version ${latest_version} failed to download. Attempting to fall back to ${prev_version} to retry..."
        go install github.com/air-verse/air@v${prev_version}
    fi
}

get_github_filename() {
    local version=$1
    local arch=$2
    echo "air_${version}_linux_${arch}"
}

install_from_github() {
    local latest_version=$1
    local prev_version=$2

    check_packages wget
    local arch=$(dpkg --print-architecture)

    local filename=$(get_github_filename $latest_version $arch)

    set +e

    mkdir -p /tmp/air
    pushd /tmp/air
    wget ${GITHUB_REPO}/releases/download/v${latest_version}/${filename}
    local exit_code=$?

    set -e

    if [ "$exit_code" != "0" ]; then
        # Handle situation where git tags are ahead of what was is available to actually download
        echo "(!) air version ${latest_version} failed to download. Attempting to fall back to ${prev_version} to retry..."
        filename=$(get_github_filename $prev_version $arch)
        wget ${GITHUB_REPO}/releases/download/v${prev_version}/${filename}
    fi

    chmod 755 /tmp/air/${filename}
    mv /tmp/air/${filename} /usr/local/bin/air
    popd
    rm -rf /tmp/air
}

# Install curl, git if missing
check_packages curl ca-certificates git

version_list=$(git ls-remote --tags ${GITHUB_REPO})

versions=($(find_latest_versions $AIR_VERSION version_list "tags/v"))
if [ $? -eq 1 ]; then
    echo "Can't find appropriate version"
    exit 1
fi

latest_version=${versions[0]}
prev_version=${versions[1]:-$latest_version}

echo "Downloading air v${latest_version}...."

if [ "$INSTALL_DIRECTLY_FROM_GITHUB_RELEASE" = "true" ]; then
    install_from_github $latest_version $prev_version
else
    install_using_go $latest_version $prev_version
fi

# Clean up
rm -rf /var/lib/apt/lists/*