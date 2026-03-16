# MC-Terrarium Initialization Guide

## Overview

MC-Terrarium uses **OpenBao** (Vault-compatible) for centralized CSP credential management.
Follow the steps below to prepare credentials, start the system, and register credentials into OpenBao.

## Step 1. Prepare CSP Credentials

MC-Terrarium uses the same credential format as [CB-Tumblebug](https://github.com/cloud-barista/cb-tumblebug/tree/main/init).

### 1-1. Download the credential template

```bash
mkdir -p ~/.cloud-barista
wget -O ~/.cloud-barista/credentials.yaml \
  https://raw.githubusercontent.com/cloud-barista/cb-tumblebug/main/init/template.credentials.yaml
```

### 1-2. Edit with your CSP credentials

```bash
vi ~/.cloud-barista/credentials.yaml
```

Fill in the sections for each CSP you plan to use (AWS, GCP, Azure, Alibaba, Tencent, IBM, NCP, etc.).

### 1-3. Encrypt the credential file

```bash
wget -O ./encCredential.sh \
  https://raw.githubusercontent.com/cloud-barista/cb-tumblebug/main/init/encCredential.sh
chmod +x ./encCredential.sh
./encCredential.sh
```

This creates `~/.cloud-barista/credentials.yaml.enc` and removes the plaintext file.

> To re-edit credentials later:
>
> ```bash
> wget -O ./decCredential.sh \
>   https://raw.githubusercontent.com/cloud-barista/cb-tumblebug/main/init/decCredential.sh
> chmod +x ./decCredential.sh
> ./decCredential.sh
> vi ~/.cloud-barista/credentials.yaml
> ./encCredential.sh
> ```

## Step 2. Start the System

```bash
make compose
```

This single command performs the following automatically:

1. Builds the mc-terrarium Docker image from source
2. Starts OpenBao container first
3. Detects whether OpenBao needs initialization or unsealing:
   - **First run**: Initializes OpenBao (generates unseal key + root token), writes `VAULT_TOKEN` to `.env`
   - **Restart**: Unseals OpenBao using the existing unseal key
4. Starts mc-terrarium with the generated token

After this step, the system is running but CSP credentials are not yet registered.

## Step 3. Register CSP Credentials

```bash
make init
```

This is an **interactive** command that:

1. Prompts for the encryption password to decrypt `~/.cloud-barista/credentials.yaml.enc`
2. Registers each CSP credential into OpenBao KV v2 (`secret/csp/{provider}`)
3. Creates placeholder secrets (empty values) for CSPs not in your credential file

> **Why placeholders?** OpenTofu templates reference `vault_kv_secret_v2` data sources for all CSPs.
> Placeholders prevent `tofu plan`/`apply` from failing when a CSP credential is not configured.
> Existing secrets are never overwritten by placeholders.

After this step, mc-terrarium is fully operational. Access the API at:

**Swagger UI**: http://localhost:8055/terrarium/swagger/index.html

## Resetting the System

### Reset Terrarium Data Only (keep OpenBao credentials)

```bash
make clean-data     # Stop services + delete terrarium workspace data
make compose        # Rebuild + restart (auto-unseal, no re-init needed)
```

No need to re-run `make init` — OpenBao data and credentials are preserved.

### Full Reset (including OpenBao)

```bash
make clean-all      # Stop services + delete all data (requires sudo)
make compose        # Rebuild + re-initialize OpenBao from scratch
make init           # Re-register CSP credentials
```

This deletes everything: terrarium workspaces, OpenBao data, unseal key, and token.

## Makefile Targets

| Target              | Description                                  |
| ------------------- | -------------------------------------------- |
| `make compose`      | Build + start all (auto-init/unseal OpenBao) |
| `make compose-up`   | Start pre-built images (auto-unseal OpenBao) |
| `make compose-down` | Stop all services                            |
| `make init`         | Register CSP credentials (interactive)       |
| `make unseal`       | Manually unseal OpenBao                      |
| `make clean-data`   | Delete terrarium data, keep OpenBao          |
| `make clean-all`    | Delete all data including OpenBao (sudo)     |

## Credential Paths in OpenBao

| CSP       | Path                   | Key Names                                                                        |
| --------- | ---------------------- | -------------------------------------------------------------------------------- |
| AWS       | `secret/csp/aws`       | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`                                     |
| GCP       | `secret/csp/gcp`       | `project_id`, `client_email`, `private_key`, `private_key_id`, `client_id`       |
| Azure     | `secret/csp/azure`     | `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`     |
| Alibaba   | `secret/csp/alibaba`   | `ALIBABA_CLOUD_ACCESS_KEY_ID`, `ALIBABA_CLOUD_ACCESS_KEY_SECRET`                 |
| IBM       | `secret/csp/ibm`       | `IC_API_KEY`                                                                     |
| NCP       | `secret/csp/ncp`       | `NCLOUD_ACCESS_KEY`, `NCLOUD_SECRET_KEY`                                         |
| Tencent   | `secret/csp/tencent`   | `TENCENTCLOUD_SECRET_ID`, `TENCENTCLOUD_SECRET_KEY`                              |
| OpenStack | `secret/csp/openstack` | `OS_AUTH_URL`, `OS_USERNAME`, `OS_PASSWORD`, `OS_DOMAIN_NAME`, `OS_PROJECT_ID` |

## How It Works

```
~/.cloud-barista/credentials.yaml.enc
        ↓ make init → init.sh → init.py (decrypt in-memory)
OpenBao KV v2 (secret/csp/aws, secret/csp/gcp, ...)
        ↓ vault provider in OpenTofu
Templates read credentials at runtime
```

## Init Scripts

| Script              | Purpose                                                   |
| ------------------- | --------------------------------------------------------- |
| `init.sh`           | Entry point — orchestrates credential registration        |
| `init.py`           | Core logic — decrypts credentials, registers to OpenBao   |
| `init-openbao.sh`   | One-time OpenBao initialization (unseal key + root token) |
| `unseal-openbao.sh` | Unseals OpenBao after container restart                   |

## Troubleshooting

- **"connection refused"**: OpenBao is not running. Run `make compose`.
- **"Vault is sealed"**: Run `make unseal` or `make compose` (auto-unseals).
- **"secret not found"**: Credentials not registered. Run `make init`.
- **"permission denied"**: Token expired or missing. Check `.env` for `VAULT_TOKEN`.
- **`clean-all` permission error**: `openbao-data` is owned by uid=100. `clean-all` uses `sudo` to remove it.

## Reference

- [CB-Tumblebug init/](https://github.com/cloud-barista/cb-tumblebug/tree/main/init) — credential template, encryption/decryption scripts
