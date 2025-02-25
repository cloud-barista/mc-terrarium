#!/bin/sh

# Default version
DEFAULT_TOFU_VERSION="1.9.0"
TOFU_VERSION=${1:-$DEFAULT_TOFU_VERSION}
ARCH="amd64"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Unable to detect OS"
    exit 1
fi

echo "Detected OS: $OS"

# Fix possible DNS issue in Alpine
if [ "$OS" = "alpine" ]; then
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
fi

# Define download URLs - see https://github.com/opentofu/opentofu/releases
TOFU_APK_URL="https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_${ARCH}.apk"
TOFU_DEB_URL="https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_${ARCH}.deb"

# Install OpenTofu based on OS
if [ "$OS" = "alpine" ]; then
    echo "Installing OpenTofu for Alpine..."
    
    # Install dependencies
    apk update && apk add --no-cache curl wget bash
    
    # Try downloading with curl
    echo "Downloading OpenTofu from $TOFU_APK_URL..."
    curl -L -o tofu.apk "$TOFU_APK_URL" || {
        echo "Curl failed, trying wget..."
        wget -O tofu.apk "$TOFU_APK_URL" || {
            echo "Failed to download OpenTofu APK package"
            exit 1
        }
    }

    # Install OpenTofu APK package
    if ! apk add --allow-untrusted tofu.apk; then
        echo "Failed to install OpenTofu version ${TOFU_VERSION} on Alpine"
        exit 1
    fi
    rm tofu.apk

elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    echo "Installing OpenTofu for Ubuntu/Debian..."
    
    # Install dependencies
    apt-get update -y && apt-get install -y curl wget

    # Try downloading with curl
    echo "Downloading OpenTofu from $TOFU_DEB_URL..."
    curl -L -o tofu.deb "$TOFU_DEB_URL" || {
        echo "Curl failed, trying wget..."
        wget -O tofu.deb "$TOFU_DEB_URL" || {
            echo "Failed to download OpenTofu DEB package"
            exit 1
        }
    }

    # Install OpenTofu DEB package
    if ! dpkg -i tofu.deb; then
        echo "Failed to install OpenTofu version ${TOFU_VERSION} on Ubuntu/Debian"
        exit 1
    fi
    rm tofu.deb
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# Verify installation
if ! tofu --version; then
    echo "Failed to retrieve OpenTofu version"
    exit 1
fi

echo "OpenTofu ${TOFU_VERSION} installed successfully!"