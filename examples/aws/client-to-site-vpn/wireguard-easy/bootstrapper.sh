#!/bin/bash

# Default values for WireGuard
DEFAULT_WG_EASY_PORT="51821"
DEFAULT_WG_EASY_PASSWORD_HASH='$$2a$$12$$iSCQRRM8cJxXnCNbWWM.1.4rHSEXloWPVy6XXei0TXfMWhDsSsTVq'
DEFAULT_WG_PORT="51820"
DEFAULT_WG_ADDRESS="10.1.0.x"
DEFAULT_WG_DNS="8.8.8.8"
DEFAULT_WG_ALLOWED_IPS="10.0.0.0/8"

# Load existing .env values if the file exists
if [ -f .env ]; then
    echo "Existing .env file found. Loading values..."
    source .env
fi

# Assign default values if no existing values are found
WG_EASY_PORT=${WG_EASY_PORT:-$DEFAULT_WG_EASY_PORT}
WG_EASY_PASSWORD_HASH=${WG_EASY_PASSWORD_HASH:-$DEFAULT_WG_EASY_PASSWORD_HASH}
WG_PORT=${WG_PORT:-$DEFAULT_WG_PORT}
WG_ADDRESS=${WG_ADDRESS:-$DEFAULT_WG_ADDRESS}
WG_DNS=${WG_DNS:-$DEFAULT_WG_DNS}
WG_ALLOWED_IPS=${WG_ALLOWED_IPS:-$DEFAULT_WG_ALLOWED_IPS}

# Process command-line arguments and update values accordingly
while [ "$#" -gt 0 ]; do
  case "$1" in
    --public-ip=*)
      PUBLIC_IP="${1#*=}"
      ;;
    --wg-easy-port=*)
      WG_EASY_PORT="${1#*=}"
      ;;
    --wg-easy-password-hash=*)
      WG_EASY_PASSWORD_HASH="${1#*=}"
      ;;
    --wg-port=*)
      WG_PORT="${1#*=}"
      ;;
    --wg-address=*)
      WG_ADDRESS="${1#*=}"
      ;;
    --wg-dns=*)
      WG_DNS="${1#*=}"
      ;;
    --wg-allowed-ips=*)
      WG_ALLOWED_IPS="${1#*=}"
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 --public-ip=<PUBLIC_IP> [--wg-easy-port=<WG_EASY_PORT>] [--wg-easy-password-hash=<WG_EASY_PASSWORD_HASH>] [--wg-port=<WG_PORT>] [--wg-address=<WG_ADDRESS>] [--wg-dns=<WG_DNS>] [--wg-allowed-ips=<WG_ALLOWED_IPS>]"
      exit 1
      ;;
  esac
  shift
done

# Auto-detect public IP if not provided
if [ -z "$PUBLIC_IP" ]; then
  echo "Detecting public IP..."
  PUBLIC_IP=$(curl -s https://api.ipify.org || echo "")

  if ! [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Warning: First public IP detection failed. Trying a secondary source..."
    PUBLIC_IP=$(curl -s https://ifconfig.me || echo "")
  fi

  if ! [[ "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Failed to detect public IP automatically." >&2
    exit 1
  fi
fi

# Update the .env file with the new values
echo "Updating .env file..."
cat <<EOF > .env
# WireGuard Easy VPN Configuration
LANG=en
PUBLIC_IP=${PUBLIC_IP}
WG_EASY_PORT=${WG_EASY_PORT}
WG_EASY_PASSWORD_HASH=${WG_EASY_PASSWORD_HASH}
WG_PORT=${WG_PORT}
WG_ADDRESS=${WG_ADDRESS}
WG_DNS=${WG_DNS}
WG_ALLOWED_IPS=${WG_ALLOWED_IPS}
EOF

echo ".env file successfully updated!"
# cat .env  # Uncomment for debugging

# Download Docker Compose file if not present
COMPOSE_FILE_URL="https://raw.githubusercontent.com/cloud-barista/mc-terrarium/refs/heads/main/examples/aws/client-to-site-vpn/wireguard-easy/docker-compose.yaml"
if [ ! -f docker-compose.yaml ]; then
  echo "docker-compose.yaml not found. Downloading from $COMPOSE_FILE_URL..."
  curl -o docker-compose.yaml "$COMPOSE_FILE_URL"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download Docker Compose configuration." >&2
    exit 1
  fi
fi

# Restart Docker Compose services
echo "Starting Docker Compose..."
docker compose down  # Stop existing containers
docker compose up -d  # Start in detached mode

if [ $? -ne 0 ]; then
  echo "Error: Failed to start Docker Compose." >&2
  exit 1
fi

echo "WireGuard Easy successfully started!"
echo -e " * Access the WireGuard Easy Web Interface at:\033[92m http://${PUBLIC_IP}:${WG_EASY_PORT} \033[0m"
echo " * Note - Use 'ngrok' to securely expose the WireGuard Easy Web Interface to the public Internet."
