#!/usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Scripts must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

source ./utils.sh

PROTOC_VERSION=${VERSION:-"latest"}
INSTALL_DIRECTLY_FROM_GITHUB_RELEASE=${INSTALLDIRECTLYFROMGITHUBRELEASE:-"true"}
GITHUB_REPO=https://github.com/google/protobuf

# Exit immediately if a command exits with a non-zero status.
set -e

apt_get_update

# Clean up
rm -rf /var/lib/apt/lists/*

export DEBIAN_FRONTEND=noninteractive

get_github_filename() {
    local version=$1
    local arch=$2
    echo "protoc-${version}-linux-${arch}.zip"
}

install_from_github() {
    local version_list=$(git ls-remote --tags ${GITHUB_REPO})
    
    # Get 2 latest appropriate versions
    versions=($(find_latest_versions $PROTOC_VERSION version_list "tags/v"))
    if [ $? -eq 1 ]; then
        echo "Can't find appropriate version"
        exit 1
    fi

    latest_version=${versions[0]}
    prev_version=${versions[1]}

    echo "Downloading protoc v${latest_version}...."

    check_packages wget

    # Get architecture
    local arch=$(dpkg --print-architecture)

    # Map to generic architecture
    case "$arch" in
        amd64)
            arch="x86_64"
            ;;
        i386)
            arch="x86_32"
            ;;
        arm64)
            arch="aarch64"
            ;;
        armhf)
            arch="arm"
            ;;
        ppc64el)
            arch="ppc64le"
            ;;
        s390x)
            arch="s390x"
            ;;
        *)
            echo "Unknown architecture $arch."
            exit 1
            ;;
    esac

    local filename=$(get_github_filename $latest_version $arch)

    set +e

    # Create temporary directory
    mkdir -p /tmp/protoc
    pushd /tmp/protoc

    # Download zip file
    wget ${GITHUB_REPO}/releases/download/v${latest_version}/${filename}
    local exit_code=$?

    set -e

    if [ "$exit_code" != "0" ]; then
        # Handle situation where git tags are ahead of what was is available to actually download
        echo "(!) protoc version ${latest_version} failed to download. Attempting to fall back to ${prev_version} to retry..."
        filename=$(get_github_filename $prev_version $arch)
        wget ${GITHUB_REPO}/releases/download/v${prev_version}/${filename}
    fi

    unzip /tmp/protoc/${filename} -d /tmp/protoc

    # Install bin/
    if [[ -d /tmp/protoc/bin ]]; then
        echo "Installing binaries to /usr/local/bin/..."
        cp -r /tmp/protoc/bin/* /usr/local/bin/
    fi

    # Move include/
    if [[ -d /tmp/protoc/include ]]; then
        echo "Installing headers to /usr/local/include/..."
        cp -r /tmp/protoc/include/* /usr/local/include/
    fi

    # Remove temporary directory
    popd
    rm -rf /tmp/protoc
}

# Install curl, unzip if missing
check_packages curl ca-certificates unzip git

install_from_github

# Clean up
rm -rf /var/lib/apt/lists/*