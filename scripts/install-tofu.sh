#!/bin/bash

# Default version
DEFAULT_VERSION="1.8.3"

# Use argument or default version
VERSION=${1:-$DEFAULT_VERSION}

# Ensure that your system is up to date
apt update -y

# Ensure that you have installed the dependencies, such as `gnupg`, `software-properties-common`, `curl`, and unzip packages.
apt install -y curl 

# Download the installer script:
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
# Alternatively: wget --secure-protocol=TLSv1_2 --https-only https://get.opentofu.org/install-opentofu.sh -O install-opentofu.sh

# Give it execution permissions:
chmod +x install-opentofu.sh

# Please inspect the downloaded script

# Run the installer:
./install-opentofu.sh --install-method deb --opentofu-version ${VERSION}

# Remove the installer:
rm -f install-opentofu.sh
