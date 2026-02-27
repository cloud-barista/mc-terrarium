# MC-Terrarium Credential Setup

MC-Terrarium uses the same credential management pattern as [CB-Tumblebug](https://github.com/cloud-barista/cb-tumblebug/tree/main/init):
credentials are stored in an encrypted YAML file and registered into OpenBao at startup.

## Quick Start

### 1. Download the credential template

```bash
wget -O ~/.cloud-barista/credentials.yaml \
  https://raw.githubusercontent.com/cloud-barista/cb-tumblebug/main/init/template.credentials.yaml
```

### 2. Edit with your CSP credentials

```bash
vi ~/.cloud-barista/credentials.yaml
```

Fill in the sections for each CSP you plan to use (AWS, GCP, Azure, Alibaba, Tencent, IBM, NCP, etc.).

### 3. Encrypt the credential file

```bash
# Download encryption script from cb-tumblebug
wget -O ./encCredential.sh \
  https://raw.githubusercontent.com/cloud-barista/cb-tumblebug/main/init/encCredential.sh
chmod +x ./encCredential.sh

# Encrypt (uses AES-256-CBC via openssl)
./encCredential.sh
```

This creates `~/.cloud-barista/credentials.yaml.enc` and removes the plaintext file.

> To re-edit credentials later, decrypt first:
>
> ```bash
> wget -O ./decCredential.sh \
>   https://raw.githubusercontent.com/cloud-barista/cb-tumblebug/main/init/decCredential.sh
> chmod +x ./decCredential.sh
> ./decCredential.sh
> vi ~/.cloud-barista/credentials.yaml
> ./encCredential.sh
> ```

### 4. Initialize MC-Terrarium

```bash
docker compose up -d openbao
bash init/init.sh
```

`init.sh` will:

1. Initialize and unseal OpenBao
2. Decrypt `credentials.yaml.enc`
3. Register credentials into OpenBao KV v2 (`secret/csp/{provider}`)
4. Register **placeholder secrets** for CSPs not present in the credential file

> [!NOTE]
> **Placeholder secrets**: For any CSP defined in the key mapping but not found in your credential file,
> `register-credentials.py` automatically creates a placeholder secret with empty string values.
> This ensures `vault_kv_secret_v2` data sources do not hard-fail during `tofu plan`/`apply`,
> allowing multi-CSP templates (e.g., testbed, VPN) to initialize without requiring all CSP credentials upfront.
> Already-existing secrets in OpenBao are never overwritten by placeholders.

## How It Works

```
template.credentials.yaml   (from cb-tumblebug)
        ↓ copy & edit
~/.cloud-barista/credentials.yaml
        ↓ encCredential.sh (AES-256-CBC)
~/.cloud-barista/credentials.yaml.enc
        ↓ init/init.sh → register-credentials.py
OpenBao KV v2 (secret/csp/aws, secret/csp/gcp, ...)
        ↓ vault provider in OpenTofu
Templates / Examples read credentials at runtime
```

## Encryption Details

- **Algorithm**: AES-256-CBC with PBKDF2 (via `openssl enc`)
- **Key Management**: Encryption key is stored at `~/.cloud-barista/.tmp_enc_key` (auto-generated if not provided)
- **Decryption**: `register-credentials.py` decrypts in-memory before registering to OpenBao

## Reference

- [CB-Tumblebug init/ directory](https://github.com/cloud-barista/cb-tumblebug/tree/main/init) — credential template, encryption/decryption scripts
- [init/register-credentials.py](register-credentials.py) — decrypts and registers credentials to OpenBao
- [init/init.sh](init.sh) — orchestrates OpenBao init, unseal, and credential registration
