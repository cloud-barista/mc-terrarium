# MC-Terrarium OpenBao & Credential Initialization

## Overview

MC-Terrarium uses **OpenBao** (Vault-compatible) for centralized CSP credential management.
This guide covers how to prepare credentials, start OpenBao, and register credentials securely.

## 1. Prepare CSP Credentials

MC-Terrarium shares the same credential format as [CB-Tumblebug](https://github.com/cloud-barista/cb-tumblebug/tree/main/init).

### 1.1 Download the template
```bash
mkdir -p ~/.cloud-barista
wget -O ~/.cloud-barista/credentials.yaml \
  https://raw.githubusercontent.com/cloud-barista/cb-tumblebug/main/init/template.credentials.yaml
```

### 1.2 Edit with your credentials
```bash
vi ~/.cloud-barista/credentials.yaml
```
Fill in the sections for each CSP you plan to use (AWS, GCP, Azure, Alibaba, Tencent, IBM, NCP, etc.).

### 1.3 Encrypt the credential file
```bash
# Get the encryption script
wget -O ./encCredential.sh \
  https://raw.githubusercontent.com/cloud-barista/cb-tumblebug/main/init/encCredential.sh
chmod +x ./encCredential.sh

# Run encryption (requires a password)
./encCredential.sh
```
This creates `~/.cloud-barista/credentials.yaml.enc` and removes the plaintext file.

> [!TIP]
> To re-edit credentials later, use `decCredential.sh` from the Tumblebug repo, edit, and re-encrypt.

## 2. Start the System

```bash
make compose
```
This command performs the following automatically:
1.  **Builds** the mc-terrarium Docker image.
2.  **Starts** the OpenBao container.
3.  **Initializes/Unseals** OpenBao:
    *   **First run**: Generates unseal keys and root token (writes `VAULT_TOKEN` to `.env`).
    *   **Restart**: Auto-unseals using stored keys.
4.  **Starts** mc-terrarium with the generated token.

## 3. Register CSP Credentials

```bash
make init
```
This command registers your encrypted credentials into OpenBao KV v2 (`secret/csp/{provider}`).

### Standardized User Experience

To provide a consistent experience across **Terrarium, Tumblebug, and Beetle**, the registration script supports a single-password handover mechanism:

*   **Interactive**: Prompts for the decryption password.
*   **Automated (`MULTI_INIT_PWD`)**: If the `MULTI_INIT_PWD` environment variable is set, the script uses it automatically, enabling a single-prompt flow for multi-component systems.
*   **Key File**: Supports `--key-file` for decryption without a password.

### Infrastructure Placeholders
The script also creates **placeholder secrets** (empty values) for CSPs not in your credential file. This prevents OpenTofu plans from failing when referencing data sources for unused CSPs.

## 4. Troubleshooting

*   **"connection refused"**: OpenBao is not running. Run `make compose`.
*   **"Vault is sealed"**: Run `make unseal` or `make compose`.
*   **"secret not found"**: Credentials not registered. Run `make init`.
*   **"permission denied"**: Token expired or missing. Check `.env` for `VAULT_TOKEN`.

## 5. Credential Paths in OpenBao

| CSP           | Path                   | Key Names                                                                        |
| ------------- | ---------------------- | -------------------------------------------------------------------------------- |
| AWS           | `secret/csp/aws`       | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`                                     |
| GCP           | `secret/csp/gcp`       | `project_id`, `client_email`, `private_key`, `private_key_id`, `client_id`       |
| Azure         | `secret/csp/azure`     | `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`     |
| Alibaba Cloud | `secret/csp/alibaba`   | `ALIBABA_CLOUD_ACCESS_KEY_ID`, `ALIBABA_CLOUD_ACCESS_KEY_SECRET`                 |
| IBM Cloud     | `secret/csp/ibm`       | `IC_API_KEY`                                                                     |
| NCP           | `secret/csp/ncp`       | `NCLOUD_ACCESS_KEY`, `NCLOUD_SECRET_KEY`                                         |
| Tencent Cloud | `secret/csp/tencent`   | `TENCENTCLOUD_SECRET_ID`, `TENCENTCLOUD_SECRET_KEY`                              |
| OpenStack/DCS | `secret/csp/openstack` | `OS_AUTH_URL`, `OS_USERNAME`, `OS_PASSWORD`, `OS_DOMAIN_NAME`, `OS_PROJECT_ID` |

## 6. How It Works (OpenTofu/Vault)

Templates use the [hashicorp/vault](https://registry.terraform.io/providers/hashicorp/vault/latest) provider to read credentials at runtime:

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

## 7. Reference

*   [OpenBao Registration Script](openbao-register-creds.sh)
*   [CB-Tumblebug Initialization](https://github.com/cloud-barista/cb-tumblebug/tree/main/init)
