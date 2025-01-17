#!/bin/bash

# Initialize default values for ngrok
DEFAULT_NGROK_AUTHTOKEN=""
DEFAULT_NGROK_STATIC_DOMAIN=""
DEFAULT_TARGET_PORT=80

# Load environment variables from .env file
if [ -f .env ]; then
  source .env
fi

# Assign default values if the variables are not set
NGROK_AUTHTOKEN=${NGROK_AUTHTOKEN:-$DEFAULT_NGROK_AUTHTOKEN}
NGROK_STATIC_DOMAIN=${NGROK_STATIC_DOMAIN:-$DEFAULT_NGROK_STATIC_DOMAIN}
TARGET_PORT=${TARGET_PORT:-$DEFAULT_TARGET_PORT}

# Parse command-line arguments and update the variables
while [ "$#" -gt 0 ]; do
  case "$1" in
    --ngrok-authtoken=*)
      NGROK_AUTHTOKEN="${1#*=}"
      ;;
    --ngrok-static-domain=*)
      NGROK_STATIC_DOMAIN="${1#*=}"
      ;;
    --target-port=*)
      TARGET_PORT="${1#*=}"
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 --ngrok-authtoken=<NGROK_AUTHTOKEN> [--ngrok-static-domain=<NGROK_STATIC_DOMAIN>] [--target-port=<TARGET_PORT>]"
      exit 1
      ;;
  esac
  shift
done

# Validate required arguments
if [ -z "$NGROK_AUTHTOKEN" ]; then
  echo "Error: --ngrok-authtoken=<NGROK_AUTHTOKEN> is required."
  exit 1
fi

# Update or create the .env file
echo "Updating .env file..."
cat <<EOF > .env
NGROK_AUTHTOKEN=$NGROK_AUTHTOKEN
NGROK_STATIC_DOMAIN=$NGROK_STATIC_DOMAIN
TARGET_PORT=$TARGET_PORT
EOF

echo ".env file successfully updated!"
# cat .env  # Uncomment to display the .env file content

# Download Docker Compose file if not present
COMPOSE_FILE_URL="https://raw.githubusercontent.com/cloud-barista/mc-terrarium/refs/heads/main/examples/aws/client-to-site-vpn/ngrok/docker-compose.yaml"
if [ ! -f docker-compose.yaml ]; then
  echo "docker-compose.yaml not found. Downloading from $COMPOSE_FILE_URL..."
  curl -o docker-compose.yaml "$COMPOSE_FILE_URL"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download Docker Compose configuration." >&2
    exit 1
  fi
fi

# Start or restart the docker-compose stack
echo "Starting ngrok with Docker Compose..."
docker compose down  # Stop any existing containers
docker compose up -d  # Start in detached mode

# Wait for ngrok to start and fetch the generated URL if NGROK_STATIC_DOMAIN is not set
if [ -z "$NGROK_STATIC_DOMAIN" ]; then
  echo "Waiting for ngrok to start (Ephemeral Domain)..."
  for i in {1..20}; do  # Wait up to 20 sec
    PUBLIC_URL=$(curl -s http://localhost:4040/api/tunnels | grep -oP '"public_url":"\K[^"]+')
    if [ -n "$PUBLIC_URL" ]; then
      echo -e "ngrok Ephemeral Domain: \033[92m $PUBLIC_URL \033[0m -> http://localhost:$TARGET_PORT"
      break
    fi
    echo "Retrying... ($i)"
    sleep 1
  done

  if [ -z "$PUBLIC_URL" ]; then
    echo "Error: Failed to fetch ngrok public URL from http://localhost:4040/api/tunnels."
    echo "Check if ngrok Web Interface is enabled and accessible."
    exit 1
  fi
else
  echo -e "ngrok Static Domain: \033[92m https://$NGROK_STATIC_DOMAIN \033[0m -> http://localhost:$TARGET_PORT"
fi
