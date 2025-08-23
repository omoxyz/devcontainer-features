#!/usr/bin/env bash

# Refresh the local package index if no package list entries are stored on the system.
apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    for pkg in "$@"; do
        # Check if it's a command in PATH
        if command -v "$pkg" &> /dev/null; then
            echo "[OK] $pkg found in PATH"
            continue
        fi

        # Check if it's a Debian/Ubuntu package installed
        if dpkg -s "$pkg" &> /dev/null; then
            echo "[OK] $pkg package installed"
            continue
        fi

        # If not found, install package
        echo "$pkg not found. Installing..."
        apt_get_update
        apt-get install -y --no-install-recommends $pkg

    done
}

# Find 2 latest versions that appropriate to requested version
find_latest_versions() {
    local requested_version=$1
    local version_list=${!2}

    # Version prefix such as "tags/v"
    local prefix_regex=${3:-''}

    # Version number part separator such as "." in "1.0.0"
    local separator=${4:-"."}
    local escaped_separator=${separator//./\\.}

    local suffix_regex=${5:-''}

    # Format and sort version list
    local version_regex="${prefix_regex}\\K[0-9]+(${escaped_separator}[0-9]+){0,2}${suffix_regex}$"
    version_list="$(printf "%s\n" "${version_list[@]}" | grep -oP $version_regex| tr -d ' ' | tr $separator '.' | sort -rV)"

    if [ "${requested_version}" = "latest" ]; then
        echo "$(echo "${version_list}" | head -n 2)"
    else
        # Try to get latest matching version
    
        set +e
            local regex="^"

            # Get major version or exit
            local major="$(echo "${requested_version}" | grep -oE '^[0-9]+')"
            if [ $major != '' ]; then
                regex="${regex}${major}"
            else
                echo "Invalid version \"${requested_version}\". Use \"latest\" or MAJOR[.MINOR][.PATCH]"
                return 1
            fi

            # Get minor number or accept any
            local minor="$(echo "${requested_version}" | grep -oP '^[0-9]+\.\K[0-9]+')"
            regex="${regex}$([ "$minor" != '' ] && echo "${escaped_separator}${minor}" || echo "(${escaped_separator}[0-9]+)?")"
            

            # Get patch number or accept any
            local patch="$(echo "${requested_version}" | grep -oP '^[0-9]+\.[0-9]+\.\K[0-9]+')"
            regex="${regex}$([ "$patch" != '' ] && echo "${escaped_separator}${patch}" || echo "(${escaped_separator}[0-9]+)?")"
        set -e

        echo "$(echo "${version_list}" | grep -E -m 2 "^${regex}$")"
    fi
}