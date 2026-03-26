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

### Prepare CSP Credentials

MC-Terrarium uses **[OpenBao](https://openbao.org/)** (Vault-compatible) for centralized credential management.
CSP credentials are encrypted locally and registered into OpenBao at initialization.

```bash
# 1. Download credential template
mkdir -p ~/.cloud-barista
wget -O ~/.cloud-barista/credentials.yaml \
  https://raw.githubusercontent.com/cloud-barista/cb-tumblebug/main/init/template.credentials.yaml

# 2. Edit with your CSP credentials
vi ~/.cloud-barista/credentials.yaml

# 3. Encrypt the credential file
wget -O ./encCredential.sh \
  https://raw.githubusercontent.com/cloud-barista/cb-tumblebug/main/init/encCredential.sh
chmod +x ./encCredential.sh
./encCredential.sh
```

> For detailed steps (re-editing, decryption, supported CSPs), see [OpenBao & Credential Initialization](deployments/docker-compose/openbao/README.md).

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

## Up and Run

MC-Terrarium runs with **OpenBao** (secrets management) via Docker Compose.
The Makefile automates OpenBao initialization and unsealing.

### Usage Scenarios

| Scenario                              | Commands                                        |
| ------------------------------------- | ----------------------------------------------- |
| **Fresh start**                       | `make compose` → `make init`                    |
| **Restart** (after reboot)            | `make compose`                                  |
| **Reset app data** (keep credentials) | `make clean-data` → `make compose`              |
| **Full reset**                        | `make clean-all` → `make compose` → `make init` |

### Quick Start

```bash
# 1. Build and start all services (auto-initializes OpenBao)
make compose

# 2. Register CSP credentials into OpenBao (interactive, one-time)
make init
```

### Access Swagger UI

URL: http://localhost:8055/terrarium/swagger/index.html

> For detailed initialization guide, credential setup, and troubleshooting, see [OpenBao & Credential Initialization](deployments/docker-compose/openbao/README.md).
