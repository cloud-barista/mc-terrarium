#!/bin/bash

# Default version
DEFAULT_TOFU_VERSION="1.8.3"

# Use argument or default version
TOFU_VERSION=${1:-$DEFAULT_TOFU_VERSION}

# Ensure that your system is up to date
apt-get update -y

# Ensure that you have installed the dependencies, such as `gnupg`, `software-properties-common`, `curl`, and unzip packages.
apt-get install -y apt-transport-https ca-certificates curl gnupg git


# Set up the OpenTofu repository
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://get.opentofu.org/opentofu.gpg | tee /etc/apt/keyrings/opentofu.gpg >/dev/null
curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg >/dev/null
chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg

# Install OpenTofu
apt-get update -y
if ! apt-get install -y tofu=${TOFU_VERSION}; then
    echo "Failed to install OpenTofu version ${TOFU_VERSION}"
    exit 1
fi

# Check tofu version after installation
if ! tofu --version; then
    echo "Failed to retrieve OpenTofu version"
    exit 1
fi

# Remove the installer:
rm -f install-tofu.sh
