#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# ==============================================================================
# Remote Pre-Provisioning Script for Cloud-Migrator Node (cm-beetle)
# ==============================================================================
# Prepares the Cloud-Migrator node right up to 'make up' & 'make init':
#   1. Installs Docker Engine, Docker Compose v2, git, make, jq, and uv
#   2. Prepares ~/.cloud-barista directory for credentials.yaml.enc
#   3. Clones https://github.com/cloud-barista/cm-beetle.git into ~/cm-beetle
#   4. Runs 'make prepare-volumes' and configures deployments/docker-compose/.env
#
# Usage:
#   ./setup-cloud-migrator.sh [VM_NAME]
# ==============================================================================

VM_NAME="${1:-cloud-migrator}"
PEM_FILE="private_key_ai_stack_testbed.pem"

if [[ ! -f "$PEM_FILE" ]]; then
    echo "❌ $PEM_FILE not found. Please run 'tofu apply' first."
    exit 1
fi

echo "🔍 Retrieving Cloud-Migrator VM ($VM_NAME) information from OpenTofu..."
VM_IP=$(tofu output -json vm_public_ips | jq -r --arg k "$VM_NAME" '.[$k]')

if [[ -z "$VM_IP" || "$VM_IP" == "null" ]]; then
    echo "❌ Could not find public IP for VM '$VM_NAME'."
    exit 1
fi

echo "============================================================"
echo "🚀 Preparing Cloud-Migrator Node ($VM_NAME - $VM_IP)"
echo "============================================================"

ssh -i "$PEM_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=15 ubuntu@"$VM_IP" bash -s << 'REMOTE_EOF'
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1

# 1. Install prerequisite packages
echo "▶ [1/4] Installing prerequisite packages (git, make, gcc, jq, curl, python3)..."
sudo apt-get -o DPkg::Lock::Timeout=600 update -qq
sudo apt-get -o DPkg::Lock::Timeout=600 install -y -qq \
    git make gcc jq curl wget rsync unzip ca-certificates gnupg python3 python3-venv python3-pip

# 2. Install Docker Engine & Docker Compose v2
echo "▶ [2/4] Checking Docker Engine & Docker Compose v2..."
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sudo sh
fi
if ! docker compose version >/dev/null 2>&1; then
    sudo apt-get -o DPkg::Lock::Timeout=600 install -y -qq docker-compose-v2 || \
    sudo apt-get -o DPkg::Lock::Timeout=600 install -y -qq docker-compose-plugin
fi
sudo usermod -aG docker ubuntu
sudo systemctl enable --now containerd docker

# 3. Install uv (required by cm-beetle 'make init' -> openbao-register-creds.sh & cb-tumblebug/init/init.sh)
echo "▶ [3/4] Installing uv Python package manager..."
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
if [ -f "$HOME/.local/bin/uv" ]; then
    sudo ln -sf "$HOME/.local/bin/uv" /usr/local/bin/uv
    sudo ln -sf "$HOME/.local/bin/uvx" /usr/local/bin/uvx 2>/dev/null || true
fi
if ! grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi
mkdir -p "$HOME/.cloud-barista"
chmod 700 "$HOME/.cloud-barista"

# 4. Clone cm-beetle from GitHub & prepare volumes / .env
echo "▶ [4/4] Cloning cloud-barista/cm-beetle from GitHub & preparing environment..."
if [ ! -d "$HOME/cm-beetle/.git" ]; then
    git clone https://github.com/cloud-barista/cm-beetle.git "$HOME/cm-beetle"
else
    cd "$HOME/cm-beetle" && git pull --ff-only || true
fi

cd "$HOME/cm-beetle"
make prepare-volumes

ENV_FILE="deployments/docker-compose/.env"
if [ -f "$ENV_FILE" ]; then
    # Enable Honeybee + UI overlay and set default service credentials if empty
    sed -i 's|^COMPOSE_FILE=.*|COMPOSE_FILE=docker-compose.yaml:docker-compose.ui.yaml|' "$ENV_FILE"
    sed -i 's|^BEETLE_API_USERNAME=$|BEETLE_API_USERNAME=default|' "$ENV_FILE"
    sed -i 's|^BEETLE_API_PASSWORD=$|BEETLE_API_PASSWORD=default|' "$ENV_FILE"
    sed -i 's|^TB_API_USERNAME=$|TB_API_USERNAME=default|' "$ENV_FILE"
    sed -i 's|^TB_API_PASSWORD=$|TB_API_PASSWORD=default|' "$ENV_FILE"
    sed -i 's|^SP_API_USERNAME=$|SP_API_USERNAME=default|' "$ENV_FILE"
    sed -i 's|^SP_API_PASSWORD=$|SP_API_PASSWORD=default|' "$ENV_FILE"
    sed -i 's|^SP_POSTGRES_USER=$|SP_POSTGRES_USER=spider|' "$ENV_FILE"
    sed -i 's|^SP_POSTGRES_PASSWORD=$|SP_POSTGRES_PASSWORD=spider|' "$ENV_FILE"
    sed -i 's|^SP_POSTGRES_DB=$|SP_POSTGRES_DB=cb_spider|' "$ENV_FILE"
    sed -i 's|^TERRARIUM_API_USERNAME=$|TERRARIUM_API_USERNAME=default|' "$ENV_FILE"
    sed -i 's|^TERRARIUM_API_PASSWORD=$|TERRARIUM_API_PASSWORD=default|' "$ENV_FILE"
    sed -i 's|^POSTGRES_USER=$|POSTGRES_USER=tumblebug|' "$ENV_FILE"
    sed -i 's|^POSTGRES_PASSWORD=$|POSTGRES_PASSWORD=tumblebug|' "$ENV_FILE"
    sed -i 's|^POSTGRES_DB=$|POSTGRES_DB=tumblebug|' "$ENV_FILE"
fi

echo
echo "  ✓ Docker   : $(docker --version)"
echo "  ✓ Compose  : $(docker compose version)"
echo "  ✓ uv       : $(uv --version)"
echo "  ✓ Repo     : $HOME/cm-beetle"
REMOTE_EOF

# Also copy auto-generated source connection files to ~/cm-beetle/ on Cloud-Migrator node for convenience
if [[ -f "source_connections_private.csv" && -f "source_connections_private.json" ]]; then
    echo "📂 Copying source_connections_private.{csv,json} to $VM_NAME:~/cm-beetle/..."
    scp -i "$PEM_FILE" -o StrictHostKeyChecking=no \
        source_connections_private.csv source_connections_private.json \
        ubuntu@"$VM_IP":~/cm-beetle/ >/dev/null
fi

echo "============================================================"
echo "✅ Cloud-Migrator Node ($VM_IP) is ready for 'make up'!"
echo
echo "Next Steps:"
echo "  1) Copy your encrypted credentials to the Cloud-Migrator node:"
echo "     scp -i $PEM_FILE ~/.cloud-barista/credentials.yaml.enc ubuntu@$VM_IP:~/.cloud-barista/credentials.yaml.enc"
echo
echo "  2) SSH into the Cloud-Migrator node and start CM-Beetle:"
echo "     ssh -i $PEM_FILE ubuntu@$VM_IP"
echo "     cd ~/cm-beetle"
echo "     make up"
echo
echo "  3) In another terminal on Cloud-Migrator, register credentials:"
echo "     cd ~/cm-beetle && make init"
echo "============================================================"
