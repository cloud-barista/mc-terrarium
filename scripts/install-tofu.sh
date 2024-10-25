#!/bin/bash

# Default version
DEFAULT_TOFU_VERSION="1.8.3"

# Use argument or default version
TOFU_VERSION=${1:-$DEFAULT_TOFU_VERSION}

# Ensure that your system is up to date
apt-get update -y

# Install required packages
apt-get install -y curl git

# Install required packages and repositories
# Note: https://packages.opentofu.org/opentofu/tofu
curl -s https://packagecloud.io/install/repositories/opentofu/tofu/script.deb.sh?any=true | bash

# Install OpenTofu
if ! apt-get install -y tofu=${TOFU_VERSION}; then
    echo "Failed to install OpenTofu version ${TOFU_VERSION}"
    exit 1
fi

# Check tofu version after installation
if ! tofu --version; then
    echo "Failed to retrieve OpenTofu version"
    exit 1
fi
