#! /usr/bin/bash

source ./utils.sh

LEFTHOOK_VERSION=${VERSION:-"latest"}
INSTALL_DIRECTLY_FROM_GITHUB_RELEASE=${INSTALLDIRECTLYFROMGITHUBRELEASE:-"true"}
GITHUB_REPO=https://github.com/evilmartians/lefthook

# Exit immediately if a command exits with a non-zero status.
set -e

apt_get_update

# Clean up
rm -rf /var/lib/apt/lists/*

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Scripts must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

get_github_filename() {
    local version=$1
    local arch=$2
    echo "lefthook_${version}_${arch}.deb"
}

install_from_github() {
    local version_list=$(git ls-remote --tags ${GITHUB_REPO})
    
    versions=($(find_latest_version $LEFTHOOK_VERSION version_list "tags/v"))
    latest_version=${versions[0]}
    prev_version=${versions[1]}

    if [ $? -eq 1 ]; then
        echo "Can't find appropriate version"
        exit 1
    fi

    echo "Downloading lefthook v${latest_version}...."

    check_packages wget
    local arch=$(dpkg --print-architecture)

    local filename=$(get_github_filename $latest_version $arch)

    mkdir -p /tmp/lefthook
    pushd /tmp/lefthook
    wget ${GITHUB_REPO}/releases/download/v${latest_version}/${filename}
    local exit_code=$?

    set -e
    if [ "$exit_code" != "0" ]; then
        # Handle situation where git tags are ahead of what was is available to actually download
        echo "(!) lefthook version ${latest_version} failed to download. Attempting to fall back to ${prev_version} to retry..."
        filename=$(get_github_filename $prev_version $arch)
        wget ${GITHUB_REPO}/releases/download/v${prev_version}/${filename}
    fi

    dpkg -i /tmp/lefthook/${filename}
    popd
    rm -rf /tmp/lefthook
}

install_from_package_manager() {
    curl -1sLf 'https://dl.cloudsmith.io/public/evilmartians/lefthook/setup.deb.sh' | bash
    
    local version_list=$(get_apt_versions lefthook)
    versions=($(find_latest_version $LEFTHOOK_VERSION version_list))
    latest_version=${versions[0]}

    if [ $? -eq 1 ]; then
        echo "Can't find appropriate version"
        exit 1
    fi

    echo "Downloading Lefthook v${latest_version}..."
    apt-get install -y --no-install-recommends lefthook=${latest_version}
}

# Install curl if missing
check_packages curl ca-certificates

# Install Lefthook
if [ "${INSTALL_DIRECTLY_FROM_GITHUB_RELEASE}" = "true" ]; then
    # Install git if missing
    if ! type git > /dev/null 2>&1; then
        check_packages git
    fi

    install_from_github
else
    install_from_package_manager
fi

# Clean up
rm -rf /var/lib/apt/lists/*