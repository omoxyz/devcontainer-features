#!/usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Scripts must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

source ./utils.sh

PROTOLINT_VERSION=${VERSION:-"latest"}
GITHUB_REPO=https://github.com/yoheimuta/protolint

# Exit immediately if a command exits with a non-zero status.
set -e

apt_get_update

# Clean up
rm -rf /var/lib/apt/lists/*

export DEBIAN_FRONTEND=noninteractive

get_github_filename() {
    local version=$1
    local arch=$2
    echo "protolint_${version}_linux_${arch}.tar.gz"
}

install_from_github() {
    local version_list=$(git ls-remote --tags ${GITHUB_REPO})
    
    # Get 2 latest appropriate versions
    versions=($(find_latest_versions $PROTOLINT_VERSION version_list "tags/v"))
    if [ $? -eq 1 ]; then
        echo "Can't find appropriate version"
        exit 1
    fi

    latest_version=${versions[0]}
    prev_version=${versions[1]}

    echo "Downloading protolint v${latest_version}...."

    check_packages wget

    # Get architecture
    local arch=$(dpkg --print-architecture)

    local filename=$(get_github_filename $latest_version $arch)

    set +e

    # Create temporary directory
    mkdir -p /tmp/protolint
    pushd /tmp/protolint

    # Download zip file
    wget ${GITHUB_REPO}/releases/download/v${latest_version}/${filename}
    local exit_code=$?

    set -e

    if [ "$exit_code" != "0" ]; then
        # Handle situation where git tags are ahead of what was is available to actually download
        echo "(!) protolint version ${latest_version} failed to download. Attempting to fall back to ${prev_version} to retry..."
        filename=$(get_github_filename $prev_version $arch)
        wget ${GITHUB_REPO}/releases/download/v${prev_version}/${filename}
    fi

    tar -xvzf /tmp/protolint/${filename} -C /tmp/protolint

    # Install binaries
    cp -r /tmp/protolint/protolint /usr/local/bin/protolint
    cp -r /tmp/protolint/protoc-gen-protolint /usr/local/bin/protoc-gen-protolint

    # Remove temporary directory
    popd
    rm -rf /tmp/protolint
}

# Install curl, unzip if missing
check_packages curl ca-certificates unzip git

install_from_github

# Clean up
rm -rf /var/lib/apt/lists/*