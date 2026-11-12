# AWS AI Stack Migration Testbed (`ai-stack-testbed`)

10-Node AWS Conference Demo Testbed (**9 Source Infrastructure VMs across 3 Clusters + 1 Cloud-Migrator VM**) for demonstrating:

1. **Multi-Cluster Source Discovery & Selective Infrastructure Migration** (`CM-Honeybee` -> `CM-Beetle` -> `CB-Tumblebug`)
2. **AI Service Stack Migration (`AIMX` / `transx`)**: NVIDIA L4 24GB GPU + Ollama (`gemma4:12b` + `bge-m3`) + Kotaemon Full (`v0.12.0`, `:7860`)

---

## 1. 10-Node Architecture Overview

The VM map keys are automatically applied as Linux **hostnames** (`/etc/hostname`), enabling **CM-Beetle** to auto-classify the 9 source nodes into 3 distinct clusters (`AI Inference`, `Analytics Compute`, `Backend & DB`), alongside a dedicated **Cloud-Migrator** node:

| Category         | Cluster Group         | VM Key (Hostname)    | `service_role`   | Default Spec (Hybrid)             | Full Profile Spec | Root Disk | Configured Stack & UFW Ports                                                                               |
| :--------------- | :-------------------- | :------------------- | :--------------- | :-------------------------------- | :---------------- | :-------- | :--------------------------------------------------------------------------------------------------------- |
| **Platform (1)** | **Cloud-Migrator**    | `cloud-migrator`     | `cloud-migrator` | `m5.2xlarge` (8 vCPU, 32GB)       | `m5.2xlarge`      | **100GB** | CM-Beetle Stack (`~/cm-beetle`) + Shared SSH Key (`~/.ssh/id_rsa`)                                         |
| **Source (3)**   | **AI Inference**      | `ai-gpu-01`          | `ai-webui`       | **`g6.2xlarge`** (NVIDIA L4 24GB) | `g6.2xlarge`      | **150GB** | **Live AI Stack** (`/opt/aimx/ai-service`: Ollama `:11434` + `gemma4:12b` + `bge-m3` + Kotaemon `:7860`) |
|                  | **AI Inference**      | `ai-gpu-02`          | `ai-worker`      | `t3.xlarge` (4 vCPU, 16GB)        | `g4dn.xlarge`     | 80GB      | Ollama Worker (`22`, `11434`)                                                                             |
|                  | **AI Inference**      | `ai-gpu-03`          | `ai-worker`      | `t3.xlarge` (4 vCPU, 16GB)        | `g4dn.xlarge`     | 80GB      | vLLM / Vector Worker (`22`, `8000`, `11434`)                                                              |
| **Source (3)**   | **Analytics Compute** | `data-master-01`     | `spark-master`   | `t3.xlarge` (4 vCPU, 16GB)        | `m5.2xlarge`      | 50GB      | Spark / Airflow Master (`22`, `8080`, `7077`)                                                             |
|                  | **Analytics Compute** | `data-worker-01`     | `spark-worker`   | `t3.large` (2 vCPU, 8GB)          | `m5.xlarge`       | 50GB      | PySpark Worker (`22`, `8081`, `7077`)                                                                     |
|                  | **Analytics Compute** | `data-etl-01`        | `etl`            | `t3.large` (2 vCPU, 8GB)          | `m5.xlarge`       | 50GB      | Kafka / Logstash ETL (`22`, `9092`, `5044`)                                                               |
| **Source (3)**   | **Backend & DB**      | `db-primary-01`      | `postgres`       | `t3.large` (2 vCPU, 8GB)          | `r5.xlarge`       | 50GB      | PostgreSQL Primary (`22`, `5432`)                                                                         |
|                  | **Backend & DB**      | `backend-api-01`     | `backend-api`    | `t3.medium` (2 vCPU, 4GB)         | `t3.large`        | 50GB      | FastAPI / Nginx (`22`, `80`, `443`, `8000`)                                                               |
|                  | **Backend & DB**      | `storage-gateway-01` | `storage`        | `t3.medium` (2 vCPU, 4GB)         | `t3.large`        | 50GB      | MinIO / NFS Gateway (`22`, `9000`, `9001`, `2049`)                                                        |

---

## 2. Quick Start Guide

### Step 1. Start OpenBao (`make up`) & Load Environment Variables for OpenTofu

AWS credentials are retrieved dynamically from OpenBao (`secret/data/csp/aws`).
First, ensure OpenBao is running and unsealed via `make up` from the project root, then export `VAULT_ADDR` and `VAULT_TOKEN` in your shell for the `tofu` CLI:

```bash
# 1) Start OpenBao & mc-terrarium from the project root (auto-initializes VAULT_TOKEN & unseals OpenBao)
#    - First time only: run 'make init' after 'make up' to register ~/.cloud-barista/credentials.yaml.enc
#    - If OpenBao is already running in the background, 'make unseal' is sufficient
cd /home/ubuntu/dev/cloud-barista/mc-terrarium
make up

# 2) In a new terminal, navigate to the testbed directory
cd /home/ubuntu/dev/cloud-barista/mc-terrarium/examples/aws/ai-stack-testbed

# 3) Prepare local .env for the OpenTofu Vault provider and export variables (IMPORTANT: use set -a)
#    Option A-1 (when OpenBao is started from mc-terrarium):
grep -E '^(VAULT_ADDR|VAULT_TOKEN)=' ../../../deployments/docker-compose/.env > .env

#    Option A-2 (when OpenBao is started from cm-beetle):
#    grep -E '^(VAULT_ADDR|VAULT_TOKEN)=' ../../../../cm-beetle/deployments/docker-compose/.env > .env

#    Option B: Or manually configure .env if connecting to an external Vault/OpenBao server
#    cp .env.example .env && vi .env

set -a && source .env && set +a

# 4) Verify AWS credentials in OpenBao (Optional: requires OpenBao to be running & unsealed)
curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/secret/data/csp/aws" | jq '.data.data | keys'
```

### Step 2. Configure `allowed_cidr_blocks` & Provision the 10-Node Testbed

The AWS Security Group allows inbound traffic (SSH `:22`, Kotaemon `:7860`, Ollama `:11434`, etc.) only from inside the VPC (`10.0.0.0/16`) and the CIDR blocks listed in `allowed_cidr_blocks` in `terraform.tfvars`.

```bash
# 1) Check your current public IP address
echo "$(curl -s ifconfig.me)/32"

# 2) Ensure your public IP/CIDR is included in allowed_cidr_blocks in terraform.tfvars
vi terraform.tfvars

# (Optional) To deploy the Full GPU profile (1x g6.2xlarge + 2x g4dn.xlarge GPU nodes):
# cp terraform.tfvars.full.example terraform.tfvars

# 3) Initialize, plan, and apply (creates 27 resources: 10 VMs + network + local key/CSV/JSON/YAML files)
tofu init
tofu plan
tofu apply
```

> [!NOTE]
> During VM creation, `modules/aws/user-data.sh` performs fast OS-level initialization only (hostname assignment, SSH key & Agent Forwarding setup, and per-role UFW firewall rules). Heavy application installation (AI Stack on `ai-gpu-01` and CM-Beetle environment on `cloud-migrator`) is executed via dedicated post-deployment scripts in **Step 4** and **Step 5**.

When `tofu apply` completes, the following files are automatically generated in the current directory (`0600` permissions):

- `private_key_ai_stack_testbed.pem` / `private_key_ai_stack_testbed_oneline.pem` (SSH private keys)
- `source_connections_private.csv` / `source_connections_public.csv` (Bulk import CSV for the 9 source nodes)
- `source_connections_private.json` / `source_connections_public.json` (Bulk import JSON for the 9 source nodes)
- `source_connections_private.yaml` / `source_connections_public.yaml` (Bulk import YAML for the 9 source nodes)

---

### Step 3. Test SSH Connectivity & Firewall Status

#### 3-1. Inspect Deployment Endpoints and IP Addresses

```bash
# View key endpoints (Cloud-Migrator & AI GPU node IPs and URLs)
tofu output demo_endpoints

# List public and private IPs of all 10 VMs
tofu output vm_public_ips
tofu output vm_private_ips
```

#### 3-2. Run Automated Firewall & Node Health Check Across All 10 VMs

```bash
./check-firewall.sh
```

#### 3-3. Connect to Individual VMs via SSH

```bash
# 1) SSH into the AI Inference Primary node (ai-gpu-01)
AI_GPU_IP=$(tofu output -json vm_public_ips | jq -r '."ai-gpu-01"')
ssh -i private_key_ai_stack_testbed.pem ubuntu@$AI_GPU_IP

# 2) SSH into the Cloud-Migrator node (cloud-migrator)
CM_IP=$(tofu output -json vm_public_ips | jq -r '."cloud-migrator"')
ssh -i private_key_ai_stack_testbed.pem ubuntu@$CM_IP
```

> **Tip - Passwordless Private IP SSH from `cloud-migrator` to Source Nodes**:
> `cloud-migrator` is automatically provisioned with `/home/ubuntu/.ssh/id_rsa` and `~/.ssh/config` (`Host 10.0.*`). From inside `cloud-migrator`, you can SSH directly into any of the 9 source nodes using its private IP (`10.0.1.x`) without specifying a key file:
>
> ```bash
> # Run from inside cloud-migrator
> ssh 10.0.1.x hostname
> ```

---

### Step 4. Deploy & Verify AI Stack (Ollama + `gemma4:12b` + `bge-m3` + Kotaemon) on `ai-gpu-01`

#### 4-1. Run the Remote AI Stack Setup Script

Run `./setup-ai-stack.sh` from your local terminal to remotely install/verify the NVIDIA GPU runtime, Docker Compose v2, and NVIDIA Container Toolkit on `ai-gpu-01`, deploy `aimx-ollama` (`:11434`) and `aimx-kotaemon` (`kotaemon:main-full` `v0.12.0` on `:7860` with GPU pass-through), pull **`gemma4:12b`** (LLM) and **`bge-m3`** (multilingual embeddings) so both stay co-resident in 24GB NVIDIA L4 VRAM, pre-seed Ollama & Korean RAG defaults (`Docling`, `Korean`, `inline` citation, and `Mindmap`) in Kotaemon `sql.db`, warm up GPU inference, and normalize file permissions for `transx`:

```bash
./setup-ai-stack.sh
```

#### 4-2. Test Ollama API (`:11434`), `gemma4:12b` LLM, & `bge-m3` Embeddings via CLI

```bash
AI_GPU_IP=$(tofu output -json vm_public_ips | jq -r '."ai-gpu-01"')

# 1) Verify installed Ollama models (gemma4:12b + bge-m3)
curl -s "http://$AI_GPU_IP:11434/api/tags" | jq

# 2) Run a test inference prompt against gemma4:12b
curl -s "http://$AI_GPU_IP:11434/api/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma4:12b",
    "prompt": "Hello! Please introduce yourself in one sentence.",
    "stream": false
  }' | jq -r .response

# 3) Verify active GPU VRAM co-residency (gemma4:12b + bge-m3)
curl -s "http://$AI_GPU_IP:11434/api/ps" | jq
```

#### 4-3. Upload PDFs & Test Citation Highlighting / Mindmap in Kotaemon (`:7860`)

1. **Get the Kotaemon URL**:

   ```bash
   tofu output -json demo_endpoints | jq -r .source_kotaemon_url
   ```

   Open the output URL (e.g., `http://<ai-gpu-01-public-ip>:7860`) in your web browser and sign in with **`admin` / `admin`**.

2. **Upload PDFs & Verify Citations / Mindmap**:
   - Upload PDF files in **`Files` -> `File Collection`** (`ollama` with `gemma4:12b` + `bge-m3`, `Docling` figure/table parser, Korean response language, `inline` citation, and `Mindmap` visualization are pre-configured as defaults).
   - When uploading multiple PDFs at once, `Docling` indexes them sequentially on the GPU. Check the `note` column in the **`Files`** list (`{"tokens": ..., "loader": "DoclingReader"}`) to verify each file has finished indexing; if a long batch disconnects in the browser, refresh (`F5`) and re-upload any remaining file with `Force reindex file` checked.
   - In **`Chat`** (`File Collection` on the left):
     - Choose **`Search In File(s)`** and select target document(s) when asking regulation- or document-specific questions so chunks from other documents do not crowd out top retrieval results.
     - Choose **`Search All`** for broad cross-document questions.
   - Confirm that inline citations (`[1]`, `[2]`), right-panel highlighted evidence chunks (`[Preview]` PDF viewer), and mindmap diagrams render properly, and conversation threads are saved on the left.
   - **Persisting UI setting changes**: Adjustments made in the bottom `Chat settings` bar apply only to the current browser session. To save changes permanently to `sql.db`, update them under the top **`Settings`** tab and click **`Save`**.
   - **Pre-migration quiesce helper**: All state (uploaded PDFs, Chroma vectorstore, LanceDB docstore, SQLite `sql.db`, Ollama models, and `.nv` CUDA cache) lives under `/opt/aimx/ai-service/`. Before running `CM-Beetle` (`transx`) data transfer, `/opt/aimx/ai-service/prepare-for-migration.sh` can be invoked on `ai-gpu-01` to cleanly flush SQLite (`QUIESCED_DB_SHA256`) and normalize file ownership.

3. **(Alternative) Access via SSH Local Port Forwarding**:
   If your client IP is not in `allowed_cidr_blocks` or port `7860` is restricted by a corporate firewall, forward the ports over SSH:
   ```bash
   AI_GPU_IP=$(tofu output -json vm_public_ips | jq -r '."ai-gpu-01"')
   ssh -i private_key_ai_stack_testbed.pem -L 7860:localhost:7860 -L 11434:localhost:11434 ubuntu@$AI_GPU_IP
   ```
   While the SSH session is open, visit **`http://localhost:7860`** in your local browser.

---

### Step 5. Prepare the `cloud-migrator` Node & Start CM-Beetle

#### 5-1. Run the Remote Cloud-Migrator Pre-Provisioning Script

Run `./setup-cloud-migrator.sh` from your local terminal to prepare the `cloud-migrator` node right up to `make up` (installs Docker Engine, Docker Compose v2, `uv`, clones `https://github.com/cloud-barista/cm-beetle.git` into `~/cm-beetle`, runs `make prepare-volumes`, configures `deployments/docker-compose/.env`, and copies `source_connections_private.{csv,json,yaml}` to `~/cm-beetle/`):

```bash
./setup-cloud-migrator.sh
```

#### 5-2. Copy Encrypted Credentials (`credentials.yaml.enc`) via `scp`

Copy your encrypted Cloud-Barista credential file (`~/.cloud-barista/credentials.yaml.enc`) from your local machine to the `cloud-migrator` node:

```bash
CM_IP=$(tofu output -json vm_public_ips | jq -r '."cloud-migrator"')

scp -i private_key_ai_stack_testbed.pem \
  ~/.cloud-barista/credentials.yaml.enc \
  ubuntu@$CM_IP:~/.cloud-barista/credentials.yaml.enc
```

#### 5-3. Start CM-Beetle (`make up`) & Register Credentials (`make init`)

SSH into the `cloud-migrator` node to start the platform services and initialize credentials:

```bash
# 1) SSH into cloud-migrator and start all services (OpenBao, CB-Spider, CB-Tumblebug, CM-Honeybee, CM-Beetle)
CM_IP=$(tofu output -json vm_public_ips | jq -r '."cloud-migrator"')
ssh -i private_key_ai_stack_testbed.pem ubuntu@$CM_IP

cd ~/cm-beetle
make up

# (Optional) To also start the containerized CM-Beetle UI dashboard on port 3000:
# cd ~/cm-beetle/deployments/docker-compose && docker compose --profile ui up -d

# 2) In another SSH session on cloud-migrator, register CSP credentials into OpenBao & CB-Tumblebug
cd ~/cm-beetle
make init
```

---

### Step 6. Cleanup Resources

When you have finished testing, destroy all provisioned AWS resources to avoid ongoing charges (especially from GPU and large compute instances):

```bash
set -a && source .env && set +a
tofu destroy
```

---

## 3. Auto-Generated Bulk Import Files (CM-Butterfly & CM-Beetle UX Lab)

Upon `tofu apply` completion, OpenTofu automatically generates the following files in this directory (`0600` permissions) for **9 Source Nodes** (excluding `cloud-migrator`):

1. **`private_key_ai_stack_testbed.pem`** / **`private_key_ai_stack_testbed_oneline.pem`**:
   - Raw PEM private key for SSH access and `transx` data transfer.
2. **`source_connections_private.csv`** / **`source_connections_public.csv`**:
   - **CM-Butterfly (`Import Source Connection`)** & **CM-Beetle UX Lab (`Import CSV / JSON / YAML`)** compatible CSV file with header:
     `name,description,ip_address,ssh_port,user,password,private_key`
   - Use `source_connections_private.csv` when Cloud-Migrator (Beetle/Honeybee/Butterfly) runs on `cloud-migrator` inside the same VPC (`10.0.1.0/24`).
3. **`source_connections_private.json`** / **`source_connections_public.json`**:
   - **CM-Beetle UX Lab (`Import CSV / JSON / YAML`)** compatible JSON array for 1-click registration of all 9 source servers.
4. **`source_connections_private.yaml`** / **`source_connections_public.yaml`**:
   - **CM-Beetle UX Lab (`Import CSV / JSON / YAML`)** compatible YAML list for 1-click registration of all 9 source servers (automatically copied to `~/cm-beetle/` by `./setup-cloud-migrator.sh`).
