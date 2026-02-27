# MC-Terrarium Examples

OpenTofu examples for provisioning cloud resources across multiple CSPs.

All examples use **OpenBao** (Vault-compatible) for centralized credential management — no hardcoded secrets or environment variable exports needed.

## Prerequisites

1. **Start OpenBao** (if not already running):

   ```bash
   docker compose up -d openbao
   ```

2. **Initialize and register credentials** (first time only):

   ```bash
   bash init/init.sh
   ```

   This will:
   - Initialize and unseal OpenBao
   - Register your CSP credentials into OpenBao KV v2 (`secret/csp/{provider}`)

> [!NOTE]
> For CSPs without credentials in your credential file, `init.sh` automatically registers **placeholder secrets** (empty values).
> This prevents `vault_kv_secret_v2` data sources from failing during `tofu plan`. Actual authentication failures only occur when provisioning resources on those CSPs.

3. **Set environment variables** (each terminal session):

   ```bash
   source .env
   ```

   This exports `VAULT_ADDR` and `VAULT_TOKEN` which the vault provider reads automatically.

> **Note**: Inside Docker containers, `VAULT_ADDR` and `VAULT_TOKEN` are set automatically by `docker-compose.yaml`.

## Usage

From any example directory:

```bash
cd examples/aws/basic    # (or any other example)
tofu init
tofu plan
tofu apply
tofu destroy
```

## How It Works

Each example uses the [hashicorp/vault](https://registry.terraform.io/providers/hashicorp/vault/latest) provider to read credentials from OpenBao at runtime:

```hcl
# Vault provider reads VAULT_ADDR and VAULT_TOKEN from environment
provider "vault" {}

# Read credentials from OpenBao KV v2
data "vault_kv_secret_v2" "aws" {
  mount = "secret"
  name  = "csp/aws"
}

# Use credentials in the CSP provider
provider "aws" {
  region     = "ap-northeast-2"
  access_key = data.vault_kv_secret_v2.aws.data["AWS_ACCESS_KEY_ID"]
  secret_key = data.vault_kv_secret_v2.aws.data["AWS_SECRET_ACCESS_KEY"]
}
```

## Credential Paths

| CSP           | OpenBao Path           | Key Names                                                                        |
| ------------- | ---------------------- | -------------------------------------------------------------------------------- |
| AWS           | `secret/csp/aws`       | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`                                     |
| GCP           | `secret/csp/gcp`       | `project_id`, `client_email`, `private_key`, `private_key_id`, `client_id`       |
| Azure         | `secret/csp/azure`     | `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`     |
| Alibaba Cloud | `secret/csp/alibaba`   | `ALIBABA_CLOUD_ACCESS_KEY_ID`, `ALIBABA_CLOUD_ACCESS_KEY_SECRET`                 |
| IBM Cloud     | `secret/csp/ibm`       | `IC_API_KEY`                                                                     |
| NCP           | `secret/csp/ncp`       | `NCLOUD_ACCESS_KEY`, `NCLOUD_SECRET_KEY`                                         |
| Tencent Cloud | `secret/csp/tencent`   | `TENCENTCLOUD_SECRET_ID`, `TENCENTCLOUD_SECRET_KEY`                              |
| OpenStack/DCS | `secret/csp/openstack` | `OS_AUTH_URL`, `OS_USERNAME`, `OS_PASSWORD`, `OS_DOMAIN_NAME`, `OS_PROJECT_NAME` |

## Directory Structure

```
examples/
├── alibaba/           # Alibaba Cloud examples
│   └── basic/
├── aws/               # AWS examples
│   ├── basic/
│   ├── client-to-site-vpn/
│   ├── dynamo-db/
│   ├── migration-testbed/
│   ├── mq-broker/
│   ├── mysql-db-instance/
│   ├── s3-bucket/
│   └── security-group-allowing-korea-traffic/
├── azure/             # Azure examples
│   ├── basic/
│   ├── blob-storage/
│   ├── cosmos-db/
│   ├── files-storage/
│   ├── kubernetes-service/
│   └── mysql-db/
├── dcs/               # Data Center Simulator (OpenStack) examples
│   ├── basic/
│   └── vpn-to-aws/
├── gcp/               # Google Cloud Platform examples
│   ├── basic/
│   ├── firestore-db/
│   ├── sql-db-instance/
│   └── storage-bucket/
├── ha-vpn-tunnels-between-gcp-and-aws/     # Multi-CSP VPN example
├── ha-vpn-tunnels-between-gcp-and-azure/   # Multi-CSP VPN example
├── ibm/               # IBM Cloud examples
│   └── basic/
├── import-existing-resources/   # Import existing cloud resources
├── ncp/               # Naver Cloud Platform examples
│   ├── basic/
│   ├── monogodb-instance/
│   ├── mysql/
│   └── objectstorage-bucket/
└── openbao/           # OpenBao integration reference example
    └── aws/
```

## Troubleshooting

### "Error: ... connection refused" or "vault provider error"

OpenBao is not running or not reachable:

```bash
docker compose up -d openbao
bash init/unseal-openbao.sh
source .env
```

### "Error: secret not found"

Credentials not registered yet:

```bash
bash init/init.sh
```

### "Error: permission denied"

Token may be expired or incorrect. Check your `.env` file has the correct `VAULT_TOKEN`.
