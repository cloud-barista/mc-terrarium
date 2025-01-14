#!/bin/bash

# Default values
# These variables define default configurations for WireGuard
# such as port, client address range, DNS, allowed IPs, and a default password hash.
default_port="51820"
default_address="10.1.0.x"
default_dns="8.8.8.8"
default_allowed_ips="10.0.0.0/8"
# (needs double $$, hash of 'multicloud123!'; see "How_to_generate_an_bcrypt_hash.md" for generate the hash)
default_password_hash='$$2a$$12$$iSCQRRM8cJxXnCNbWWM.1.4rHSEXloWPVy6XXei0TXfMWhDsSsTVq'

# Initialize values from arguments
# Parses command-line arguments to override default values.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --public-ip=*)
      public_ip="${1#*=}"
      ;;
    --port=*)
      wg_port="${1#*=}"
      ;;
    --default-address=*)
      wg_default_address="${1#*=}"
      ;;
    --dns=*)
      wg_default_dns="${1#*=}"
      ;;
    --allowed-ips=*)
      wg_allowed_ips="${1#*=}"
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

# Attempt to auto-detect public IP if not provided
# Automatically detects the public IP address if it is not passed as an argument.
if [ -z "$public_ip" ]; then
  public_ip=$(curl -s https://api.ipify.org || echo "")

  # If the first attempt fails or returns an invalid IP, try a secondary source
  if ! [[ "$public_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Warning: First public IP detection failed or invalid. Trying a secondary source..."
    public_ip=$(curl -s https://ifconfig.me || echo "")
  fi

  # Validate the detected public IP again
  if ! [[ "$public_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Public IP address could not be detected or is invalid: $public_ip" >&2
    exit 1
  fi
fi

# Set defaults for optional arguments if not provided
# Assigns default values to optional arguments if they are not specified.
wg_port=${wg_port:-$default_port}
wg_default_address=${wg_default_address:-$default_address}
wg_default_dns=${wg_default_dns:-$default_dns}
wg_allowed_ips=${wg_allowed_ips:-$default_allowed_ips}

# Generate the .env file
# Creates the .env file with the determined configurations.
echo "LANG=en" > .env
echo "PUBLIC_IP=${public_ip}" >> .env
echo "PASSWORD_HASH=${default_password_hash}" >> .env
echo "WG_PORT=${wg_port}" >> .env
echo "WG_DEFAULT_ADDRESS=${wg_default_address}" >> .env
echo "WG_DEFAULT_DNS=${wg_default_dns}" >> .env
echo "WG_ALLOWED_IPS=${wg_allowed_ips}" >> .env

# Display completion message
# Prints a success message and the contents of the .env file.
echo ".env file and Docker Compose setup have been completed successfully!"
echo "Contents of .env file:"
cat .env

# Check if docker-compose.yaml exists, if not download it
# Ensures the Docker Compose configuration file is available. If not, downloads it.
compose_file_url="https://raw.githubusercontent.com/cloud-barista/mc-terrarium/refs/heads/main/examples/aws/client-to-site-vpn/wireguard-easy/docker-compose.yaml"
if [ ! -f docker-compose.yaml ]; then
  echo "docker-compose.yaml not found. Downloading from $compose_file_url..."
  curl -o docker-compose.yaml "$compose_file_url"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download Docker Compose configuration." >&2
    exit 1
  fi
fi

# Start Docker Compose
# Executes the Docker Compose process to start the WireGuard VPN setup.
echo "Starting Docker Compose..."
docker compose up -d

if [ $? -ne 0 ]; then
  echo "Error: Failed to start Docker Compose." >&2
  exit 1
fi
