#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# ==============================================================================
# Remote AI Service Stack Setup Script for ai-gpu-01 (AIMX Kotaemon Reference)
# ==============================================================================
# Installs/verifies NVIDIA GPU runtime, Docker Compose v2, NVIDIA Container
# Toolkit, deploys Ollama (:11434) + Kotaemon (:7860), pulls gemma4:e2b + bge-m3,
# configures Ollama as default LLM/Embedding in Kotaemon sql.db, runs dual-model
# GPU warm-up, and normalizes file ownership for transx migration.
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
AI_EMBEDDING_MODEL=$(tofu output -json demo_endpoints | jq -r '.ai_embedding_model // "bge-m3"')

if [[ -z "$VM_IP" || "$VM_IP" == "null" ]]; then
    echo "❌ Could not find public IP for VM '$VM_NAME'."
    exit 1
fi

echo "============================================================"
echo "🚀 Setting up AIMX Kotaemon + Ollama Stack on $VM_NAME ($VM_IP)"
echo "   - Service Root    : $AI_ROOT"
echo "   - LLM Model       : $AI_MODEL"
echo "   - Embedding Model : $AI_EMBEDDING_MODEL"
echo "============================================================"

ssh -i "$PEM_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=15 ubuntu@"$VM_IP" \
    "AI_ROOT='$AI_ROOT' AI_MODEL='$AI_MODEL' AI_EMBEDDING_MODEL='$AI_EMBEDDING_MODEL' bash -s" << 'REMOTE_EOF'
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

# Ensure UFW allows Kotaemon (:7860) and Ollama (:11434) even on pre-existing VMs
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow 7860/tcp comment 'Kotaemon RAG UI HTTP' >/dev/null 2>&1 || true
    sudo ufw allow 11434/tcp comment 'Ollama LLM API' >/dev/null 2>&1 || true
fi

# 1. Verify or Install NVIDIA GPU Driver (Adapted from cm-beetle/cmd/aimx/scripts/ensure-gpu-runtime.sh)
echo "▶ [1/6] Checking NVIDIA GPU driver..."
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
echo "▶ [2/6] Checking Docker & Docker Compose v2..."
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sudo sh
fi
if ! docker compose version >/dev/null 2>&1; then
    sudo apt-get -o DPkg::Lock::Timeout=600 update -qq
    sudo apt-get -o DPkg::Lock::Timeout=600 install -y -qq docker-compose-v2 || sudo apt-get -o DPkg::Lock::Timeout=600 install -y -qq docker-compose-plugin
fi
sudo usermod -aG docker ubuntu

# 3. Verify or Install NVIDIA Container Toolkit
echo "▶ [3/6] Checking NVIDIA Container Toolkit..."
if ! command -v nvidia-ctk >/dev/null 2>&1; then
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit-list.tmp > /dev/null
    sudo mv /etc/apt/sources.list.d/nvidia-container-toolkit-list.tmp /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get -o DPkg::Lock::Timeout=600 update -qq
    sudo apt-get -o DPkg::Lock::Timeout=600 install -y -qq nvidia-container-toolkit
fi

if ! grep -q "nvidia" /etc/docker/daemon.json 2>/dev/null; then
    sudo nvidia-ctk runtime configure --runtime=docker >/dev/null 2>&1 || true
    sudo systemctl restart docker
fi
sudo systemctl start containerd docker

# Remove legacy Open WebUI container if present from an older deployment
sudo docker rm -f aimx-open-webui >/dev/null 2>&1 || true

# 4. Deploy AIMX Docker Compose Stack (Ollama + Kotaemon)
echo "▶ [4/6] Writing AIMX Docker Compose stack (Ollama + Kotaemon) in $AI_ROOT..."
sudo mkdir -p "$AI_ROOT/ollama" "$AI_ROOT/ktem_app_data"
if [ "$AI_ROOT" != "/opt/ai-stack" ] && [ ! -e /opt/ai-stack ]; then
    sudo ln -s "$AI_ROOT" /opt/ai-stack
fi

cat << COMPOSE_EOF | sudo tee "$AI_ROOT/docker-compose.yml" >/dev/null
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
      - OLLAMA_MAX_LOADED_MODELS=2
      - OLLAMA_NUM_PARALLEL=2
    volumes:
      - ./ollama:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

  kotaemon:
    # Lightweight image with built-in PDF viewer and citation highlighting.
    image: ghcr.io/cinnamon/kotaemon:main-lite
    container_name: aimx-kotaemon
    restart: unless-stopped
    ports:
      - "7860:7860"
    environment:
      - GRADIO_SERVER_NAME=0.0.0.0
      - GRADIO_SERVER_PORT=7860
      - KH_OLLAMA_URL=http://ollama:11434/v1/
      - LOCAL_MODEL=$AI_MODEL
      - LOCAL_MODEL_EMBEDDINGS=$AI_EMBEDDING_MODEL
      - KH_FEATURE_USER_MANAGEMENT=true
      - KH_FEATURE_USER_MANAGEMENT_ADMIN=admin
      - KH_FEATURE_USER_MANAGEMENT_PASSWORD=admin
    volumes:
      - ./ktem_app_data:/app/ktem_app_data
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
sudo chown -R "$(id -un):$(id -gn)" "$DIR"
sudo chmod -R u+rwX,g+rX,o+rX "$DIR"
echo "QUIESCED_DB_SHA256=$(sha256sum "$DIR/ktem_app_data/user_data/sql.db" 2>/dev/null | awk '{print $1}')"
sudo docker compose up -d
PREP_EOF
sudo chmod +x "$AI_ROOT/prepare-for-migration.sh"

# 5. Start Ollama First & Pull LLM + Embedding Models
echo "▶ [5/6] Starting Ollama (:11434) and pulling models ($AI_MODEL + $AI_EMBEDDING_MODEL)..."
echo "PULLING_MODELS" | sudo tee /var/log/ai-stack-status.log >/dev/null
cd "$AI_ROOT"
for attempt in 1 2 3; do
    if sudo docker compose up -d ollama; then
        break
    fi
    echo "  ⚠️ docker compose up -d ollama failed (attempt $attempt/3), retrying in 10s..."
    sudo systemctl start containerd docker
    sleep 10
done

for i in $(seq 1 30); do
    if curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

for MODEL_TAG in "$AI_MODEL" "$AI_EMBEDDING_MODEL"; do
    echo "  ⬇ Pulling Ollama model: $MODEL_TAG"
    for attempt in 1 2 3; do
        if sudo docker exec aimx-ollama ollama pull "$MODEL_TAG"; then
            break
        fi
        echo "  ⚠️ ollama pull $MODEL_TAG failed (attempt $attempt/3), retrying in 10s..."
        sleep 10
    done
done

# 6. Start Kotaemon (:7860), Set Ollama as Default in sql.db, and Pre-warm Both Models in T4 VRAM
echo "▶ [6/6] Starting Kotaemon (:7860) and activating Ollama defaults..."
echo "STARTING_KOTAEMON" | sudo tee /var/log/ai-stack-status.log >/dev/null
for attempt in 1 2 3; do
    if sudo docker compose up -d; then
        break
    fi
    echo "  ⚠️ docker compose up -d failed (attempt $attempt/3), retrying in 10s..."
    sudo systemctl start containerd docker
    sleep 10
done

echo "  ⏳ Waiting for Kotaemon (:7860) and ktem_app_data/user_data/sql.db initialization..."
SQL_DB="$AI_ROOT/ktem_app_data/user_data/sql.db"
for i in $(seq 1 60); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7860/ || echo "000")
    if [[ "$HTTP_CODE" =~ ^(200|302|307)$ ]] && sudo test -s "$SQL_DB"; then
        echo "  ✓ Kotaemon (:7860) and sql.db initialized!"
        break
    fi
    sleep 5
done

# Activate 'ollama' as default LLM and Embedding model in Kotaemon sql.db so PDF indexing works out-of-the-box
UPDATED_TABLES=$(sudo python3 - "$SQL_DB" << 'PY_EOF'
import sqlite3, sys
db_path = sys.argv[1]
conn = sqlite3.connect(db_path, timeout=10)
cur = conn.cursor()
changed = 0
for table in ("llm", "embedding", "resources__llm", "resources__embedding"):
    exists = cur.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?", (table,)
    ).fetchone()
    if not exists:
        continue
    has_ollama = cur.execute(
        f'SELECT 1 FROM "{table}" WHERE name=?', ("ollama",)
    ).fetchone()
    if has_ollama:
        already_default = cur.execute(
            f'SELECT "default" FROM "{table}" WHERE name=?', ("ollama",)
        ).fetchone()
        if not already_default or already_default[0] != 1:
            cur.execute(f'UPDATE "{table}" SET "default"=0')
            cur.execute(f'UPDATE "{table}" SET "default"=1 WHERE name=?', ("ollama",))
            changed += 1
conn.commit()
conn.close()
print(changed)
PY_EOF
)

if [[ "${UPDATED_TABLES:-0}" != "0" ]]; then
    echo "  ✓ Activated 'ollama' as default LLM & Embedding in sql.db; restarting aimx-kotaemon..."
    sudo docker restart aimx-kotaemon >/dev/null
    for i in $(seq 1 45); do
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7860/ || echo "000")
        if [[ "$HTTP_CODE" =~ ^(200|302|307)$ ]]; then
            break
        fi
        sleep 3
    done
fi

echo "  🔥 Pre-warming $AI_MODEL and $AI_EMBEDDING_MODEL into Tesla T4 VRAM..."
curl -sf http://localhost:11434/api/generate \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$AI_MODEL\",\"prompt\":\"Hello from AIMX Source GPU Node!\",\"stream\":false,\"keep_alive\":\"30m\"}" >/dev/null 2>&1 || true
curl -sf http://localhost:11434/api/embed \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$AI_EMBEDDING_MODEL\",\"input\":\"Cloud-Barista conference presentation RAG migration\",\"keep_alive\":\"30m\"}" >/dev/null 2>&1 || true

# Normalize permissions so ubuntu SSH user can rsync all model blobs and ktem_app_data via transx
sync
sudo chown -R ubuntu:ubuntu "$AI_ROOT"
sudo chmod -R u+rwX,g+rX,o+rX "$AI_ROOT"

echo "AI_STACK_READY" | sudo tee /var/log/ai-stack-status.log >/dev/null
echo
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
REMOTE_EOF

echo "============================================================"
echo "✅ AIMX Kotaemon + Ollama Stack Ready on $VM_NAME ($VM_IP)!"
echo "   - Kotaemon URL   : http://$VM_IP:7860  (Login: admin / admin)"
echo "   - Ollama API URL : http://$VM_IP:11434/api/tags"
echo "   - Active Models  : $AI_MODEL (LLM) + $AI_EMBEDDING_MODEL (Embeddings)"
echo "============================================================"
