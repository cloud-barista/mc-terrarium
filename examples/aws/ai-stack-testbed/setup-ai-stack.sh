#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# ==============================================================================
# Remote AI Service Stack Setup Script for ai-gpu-01 (AIMX Reference)
# ==============================================================================
# Installs/verifies NVIDIA GPU runtime, Docker Compose v2, NVIDIA Container
# Toolkit, deploys Ollama (:11434) + Open WebUI (:3000), pulls gemma4:e2b,
# runs warm-up inference, and normalizes file ownership for transx migration.
#
# Usage:
#   ./setup-ai-stack.sh [VM_NAME]
# ==============================================================================

VM_NAME="${1:-ai-gpu-01}"
PEM_FILE="private_key_ai_stack_testbed.pem"

if [[ ! -f "$PEM_FILE" ]]; then
    echo "❌ $PEM_FILE not found. Please run 'tofu apply' first."
    exit 1
fi

echo "🔍 Retrieving target VM ($VM_NAME) information from OpenTofu..."
VM_IP=$(tofu output -json vm_public_ips | jq -r --arg k "$VM_NAME" '.[$k]')
AI_ROOT=$(tofu output -json demo_endpoints | jq -r '.ai_service_root_dir // "/opt/aimx/ai-service"')
AI_MODEL=$(tofu output -json demo_endpoints | jq -r '.ai_model_name // "gemma4:e2b"')

if [[ -z "$VM_IP" || "$VM_IP" == "null" ]]; then
    echo "❌ Could not find public IP for VM '$VM_NAME'."
    exit 1
fi

echo "============================================================"
echo "🚀 Setting up AIMX AI Service Stack on $VM_NAME ($VM_IP)"
echo "   • Service Root : $AI_ROOT"
echo "   • LLM Model    : $AI_MODEL"
echo "============================================================"

ssh -i "$PEM_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=15 ubuntu@"$VM_IP" \
    "AI_ROOT='$AI_ROOT' AI_MODEL='$AI_MODEL' bash -s" << 'REMOTE_EOF'
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=l
export NEEDRESTART_SUSPEND=1

echo "INSTALLING_RUNTIME" | sudo tee /var/log/ai-stack-status.log >/dev/null

# Prevent background apt/needrestart from restarting containerd during large image pulls
sudo rm -f /etc/needrestart/conf.d/99-autorestart.conf
if [ -d /etc/needrestart/conf.d ]; then
    echo '$nrconf{restart} = "l";' | sudo tee /etc/needrestart/conf.d/99-autorestart.conf >/dev/null
fi
sudo systemctl stop apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service 2>/dev/null || true

# 1. Verify or Install NVIDIA GPU Driver (Adapted from cm-beetle/cmd/aimx/scripts/ensure-gpu-runtime.sh)
echo "▶ [1/5] Checking NVIDIA GPU driver..."
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    DRV_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 || echo "unknown")
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || echo "NVIDIA GPU")
    echo "  ✓ NVIDIA GPU driver active: $GPU_NAME (Driver $DRV_VER)"
else
    echo "  ⚠️ NVIDIA driver not active; installing GPU driver..."
    sudo apt-get -o DPkg::Lock::Timeout=600 update -qq
    sudo apt-get -o DPkg::Lock::Timeout=600 install -y -qq pciutils build-essential dkms "linux-headers-$(uname -r)" || true
    UBUNTU_VER=$(. /etc/os-release 2>/dev/null && echo "$VERSION_ID" | tr -d '.' || echo "2204")
    REPO_DIST="ubuntu2204"
    [ "$UBUNTU_VER" = "2404" ] && REPO_DIST="ubuntu2404"
    KEYRING_FILE=$(mktemp)
    curl -fsSL "https://developer.download.nvidia.com/compute/cuda/repos/$REPO_DIST/x86_64/cuda-keyring_1.1-1_all.deb" -o "$KEYRING_FILE"
    sudo dpkg -i --force-confdef --force-confold "$KEYRING_FILE" || true
    rm -f "$KEYRING_FILE"
    sudo apt-get -o DPkg::Lock::Timeout=600 update -qq
    for CANDIDATE in cuda-drivers-580-open cuda-drivers-580 nvidia-driver-580-open nvidia-driver-580 cuda-drivers; do
        if sudo apt-get -o DPkg::Lock::Timeout=600 -o Dpkg::Options::="--force-overwrite" install -y -qq "$CANDIDATE"; then
            echo "  ✓ Installed $CANDIDATE"
            break
        fi
    done
    sudo apt-get -o DPkg::Lock::Timeout=600 install -y -qq nvidia-modprobe || true
    sudo modprobe nvidia 2>/dev/null || true
    sudo modprobe nvidia-uvm 2>/dev/null || true
fi

# 2. Verify or Install Docker & Docker Compose v2
echo "▶ [2/5] Checking Docker & Docker Compose v2..."
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sudo sh
fi
if ! docker compose version >/dev/null 2>&1; then
    sudo apt-get -o DPkg::Lock::Timeout=600 update -qq
    sudo apt-get -o DPkg::Lock::Timeout=600 install -y -qq docker-compose-v2 || sudo apt-get -o DPkg::Lock::Timeout=600 install -y -qq docker-compose-plugin
fi
sudo usermod -aG docker ubuntu

# 3. Verify or Install NVIDIA Container Toolkit
echo "▶ [3/5] Checking NVIDIA Container Toolkit..."
if ! command -v nvidia-ctk >/dev/null 2>&1; then
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
    sudo apt-get -o DPkg::Lock::Timeout=600 update -qq
    sudo apt-get -o DPkg::Lock::Timeout=600 install -y -qq nvidia-container-toolkit
fi

if ! grep -q "nvidia" /etc/docker/daemon.json 2>/dev/null; then
    sudo nvidia-ctk runtime configure --runtime=docker >/dev/null 2>&1 || true
    sudo systemctl restart docker
fi
sudo systemctl start containerd docker

# 4. Deploy AIMX Docker Compose Stack (Ollama + Open WebUI)
echo "▶ [4/5] Deploying AIMX Docker Compose stack in $AI_ROOT..."
sudo mkdir -p "$AI_ROOT/ollama" "$AI_ROOT/open-webui"
if [ "$AI_ROOT" != "/opt/ai-stack" ] && [ ! -e /opt/ai-stack ]; then
    sudo ln -s "$AI_ROOT" /opt/ai-stack
fi

cat << 'COMPOSE_EOF' | sudo tee "$AI_ROOT/docker-compose.yml" >/dev/null
services:
  ollama:
    image: ollama/ollama:latest
    container_name: aimx-ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    environment:
      - OLLAMA_LOAD_TIMEOUT=15m
      - OLLAMA_KEEP_ALIVE=30m
    volumes:
      - ./ollama:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: aimx-open-webui
    restart: unless-stopped
    ports:
      - "3000:8080"
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - WEBUI_AUTH=False
    volumes:
      - ./open-webui:/app/backend/data
    depends_on:
      - ollama
COMPOSE_EOF

cat << 'PREP_EOF' | sudo tee "$AI_ROOT/prepare-for-migration.sh" >/dev/null
#!/bin/bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
sudo docker compose stop && sync
sleep 3
sudo chown -R ubuntu:ubuntu "$DIR"
sudo chmod -R u+rwX,g+rX,o+rX "$DIR"
echo "QUIESCED_DB_SHA256=$(sha256sum "$DIR/open-webui/webui.db" 2>/dev/null | awk '{print $1}')"
sudo docker compose up -d
PREP_EOF
sudo chmod +x "$AI_ROOT/prepare-for-migration.sh"

echo "STARTING_CONTAINERS" | sudo tee /var/log/ai-stack-status.log >/dev/null
cd "$AI_ROOT"
for attempt in 1 2 3; do
    if sudo docker compose up -d; then
        break
    fi
    echo "  ⚠️ docker compose up -d failed (attempt $attempt/3), retrying in 10s..."
    sudo systemctl start containerd docker
    sleep 10
done

echo "  ⏳ Waiting for Ollama (:11434) and Open WebUI (:3000) endpoints..."
for i in $(seq 1 36); do
    if curl -sf http://localhost:11434/api/tags >/dev/null 2>&1 && curl -sf http://localhost:3000/api/config >/dev/null 2>&1; then
        echo "  ✓ Ollama (:11434) and Open WebUI (:3000) are online!"
        break
    fi
    sleep 5
done

# 5. Pull LLM Model & Warm Up
echo "▶ [5/5] Pulling LLM model ($AI_MODEL) & warming up GPU inference..."
echo "PULLING_MODEL_$AI_MODEL" | sudo tee /var/log/ai-stack-status.log >/dev/null
for attempt in 1 2 3; do
    if sudo docker exec aimx-ollama ollama pull "$AI_MODEL"; then
        break
    fi
    echo "  ⚠️ ollama pull failed (attempt $attempt/3), retrying in 10s..."
    sleep 10
done

curl -sf http://localhost:11434/api/generate \
    -d "{\"model\":\"$AI_MODEL\",\"prompt\":\"Hello from AIMX Source GPU Node!\",\"stream\":false,\"keep_alive\":\"30m\"}" >/dev/null 2>&1 || true

# Normalize permissions so ubuntu SSH user can rsync all model blobs and webui.db via transx
sync
sudo chown -R ubuntu:ubuntu "$AI_ROOT"
sudo chmod -R u+rwX,g+rX,o+rX "$AI_ROOT"

echo "AI_STACK_READY" | sudo tee /var/log/ai-stack-status.log >/dev/null
echo
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
REMOTE_EOF

echo "============================================================"
echo "✅ AIMX AI Service Stack Ready on $VM_NAME ($VM_IP)!"
echo "   • Open WebUI URL : http://$VM_IP:3000"
echo "   • Ollama API URL : http://$VM_IP:11434/api/tags"
echo "============================================================"
