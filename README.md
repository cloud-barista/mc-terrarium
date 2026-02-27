# Multi-Cloud Terrarium

<p align="center">
  <img src="https://github.com/user-attachments/assets/84238cbf-aef0-49ac-a1b5-2750ac1d2a9d" width="75%" height="75%" >
</p>

<p align="center">
  <strong>🤝 In Synergy with Cloud-Barista</strong><br>
  <strong>🚀 Powered by OpenTofu</strong><br>
  <strong>🔐 Secured by OpenBao</strong>
</p>

**Multi-Cloud Terrarium (mc-terrarium)** is an open-source project designed to provide an environment—an **infrastructure terrarium**—that enhances multi-cloud infrastructure management.

## 🌟 Features & Components

The infrastructure terrarium consists of:

- **Multi-Cloud Infrastructure Metadata**: Managed by Cloud-Barista to provide a unified view of multi-cloud environments.
- **Infrastructure Enrichment with OpenTofu**: Extends Cloud-Barista’s capabilities by provisioning additional resources and services beyond its native support.
- **Secure Credential Management with OpenBao**: Securely stores and provides CSP credentials via a Vault-compatible API — no hardcoded secrets or environment variable exports needed.
- **Infrastructure Code (.tf)**: Defines and structures infrastructure components and enrichments.
- **Other Evolving Components**: Continuously enhancing multi-cloud infrastructure capabilities.

## 🌍 Multi-Cloud Networking & Beyond

Currently, mc-terrarium provides **multi-cloud networking** features, such as **site-to-site VPN** setup. It will continue to evolve, enabling you to seamlessly build and manage the multi-cloud infrastructure you need.

## Prerequisites

### Install OpenTofu

- See [Installing OpenTofu](https://opentofu.org/docs/intro/install/)
- Refer to [the custom installer for Ubuntu 22.04](https://github.com/cloud-barista/mc-terrarium/blob/main/scripts/install-tofu.sh)

### Get source code

In this readme, the default root directory is `~/mc-terrarium`.

```bash
git clone https://github.com/cloud-barista/mc-terrarium.git ~/mc-terrarium
```

### Install swag

If you got an error because of missing swag, install swag:

```bash
go install github.com/swaggo/swag/cmd/swag@latest
```

### Prepare credentials

MC-Terrarium uses **[OpenBao](https://openbao.org/)** (Vault-compatible) for centralized credential management.
CSP credentials are securely stored in OpenBao and read at runtime — no need to export environment variables manually.

Prepare your credential source file:

- Store your CSP credentials in `~/.cloud-barista/credentials.yaml.enc`
- Refer to the README and templates in the [`/secrets`](secrets/) directory for credential formats per CSP

> **Note**: The initialization script (`init/init.sh`) will register these credentials into OpenBao automatically.

## Development Tools

### OpenTofu MCP Server Integration (for contributors)

This enables AI-powered assistance **for your enhanced development experience**, such as OpenTofu registry search, documentation access, and code assistance through AI tools like GitHub Copilot.

We use the **npx-based installation** for reliable access to OpenTofu registry data and documentation. SSE (Server-Sent Events) transport appears to be deprecated and being replaced with Streamable HTTP transport in MCP.

**Setup for VS Code:**

- Create `.vscode/mcp.json` in your workspace:

```json
{
  "servers": {
    "opentofu": {
      "command": "npx",
      "args": ["-y", "@opentofu/opentofu-mcp-server"]
    }
  },
  "inputs": []
}
```

For other editors (Cursor) or additional setup options, see the [OpenTofu MCP Server repository](https://github.com/opentofu/opentofu-mcp-server).

## Up and run MC-Terrarium

MC-Terrarium runs with **OpenBao** (secrets management) via Docker Compose.

### First-time setup

1. **Start OpenBao**:

   ```bash
   docker compose up -d openbao
   ```

2. **Initialize OpenBao and register credentials** (one-time):

   ```bash
   bash init/init.sh
   ```

   This will:
   - Initialize and unseal OpenBao (generates unseal key + root token)
   - Register your CSP credentials into OpenBao KV v2 (`secret/csp/{provider}`)

> [!NOTE]
> For CSPs without credentials in your credential file, `init.sh` automatically registers **placeholder secrets** (empty values) into OpenBao.
> This prevents `vault_kv_secret_v2` data sources from failing during `tofu plan`/`apply`.
> Templates that reference unregistered CSPs will initialize without errors — actual authentication failures only occur if you attempt to provision resources on those CSPs.

3. **Start all services**:

   ```bash
   make compose-up
   ```

> [!NOTE]
> `make compose-up` automatically attempts to unseal OpenBao after starting the containers.
> After a restart, OpenBao needs to be unsealed again — this is handled automatically by the Makefile target.

### Build from source and run

To build from source and start all services:

```bash
make compose
```

### For local development (without Docker)

When running mc-terrarium outside of Docker, export OpenBao connection variables:

```bash
source .env
```

This exports `VAULT_ADDR` and `VAULT_TOKEN` which the Vault provider reads automatically.

> **Note**: Inside Docker containers, `VAULT_ADDR` and `VAULT_TOKEN` are set automatically by `docker-compose.yaml`.

### Access Swagger UI

You can find the default username and password to access the API dashboard when the API server runs.

URL: http://localhost:8055/terrarium/swagger/index.html

Note - You can find API documentation on Swagger UI.

### Credential paths in OpenBao

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

### Troubleshooting

- **"connection refused" or "vault provider error"**: OpenBao is not running or sealed. Run `docker compose up -d openbao && bash init/unseal-openbao.sh`.
- **"secret not found"**: Credentials not registered. Run `bash init/init.sh`.
- **"permission denied"**: Token may be expired. Check your `.env` file for the correct `VAULT_TOKEN`.
