#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "protolint version" protolint version
check "protoc-gen-protolint " protoc-gen-protolint version

reportResults