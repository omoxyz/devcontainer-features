#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "air version" air -v

reportResults