# Hands-on Guide: AWS-DCS VPN Connectivity Test

This guide walks you through testing VPN connectivity between AWS and DCS (OpenStack) using the MC-Terrarium API. You will create a testbed with VMs in both AWS and DCS, establish a VPN connection between them, verify connectivity via ping, and then clean up all resources.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
  - [1. Credential Preparation](#1-credential-preparation)
  - [2. System Launch via make compose](#2-system-launch-via-make-compose)
- [Step-by-Step Guide](#step-by-step-guide)
  - [Step 1: Health Check](#step-1-health-check)
  - [Step 2: Create a Terrarium for Testbed](#step-2-create-a-terrarium-for-testbed)
  - [Step 3: Create the Testbed (AWS + DCS)](#step-3-create-the-testbed-aws--dcs)
  - [Step 4: Get Testbed Information](#step-4-get-testbed-information)
  - [Step 5: Create a Terrarium for VPN](#step-5-create-a-terrarium-for-vpn)
  - [Step 6: Create AWS-to-DCS VPN Connection](#step-6-create-aws-to-dcs-vpn-connection)
  - [Step 7: Get VPN Connection Information](#step-7-get-vpn-connection-information)
  - [Step 8: Connectivity Test (Ping)](#step-8-connectivity-test-ping)
  - [Step 9: Delete VPN Connection](#step-9-delete-vpn-connection)
  - [Step 10: Delete VPN Terrarium](#step-10-delete-vpn-terrarium)
  - [Step 11: Delete the Testbed](#step-11-delete-the-testbed)
  - [Step 12: Delete Testbed Terrarium](#step-12-delete-testbed-terrarium)
- [Troubleshooting](#troubleshooting)
- [Notes](#notes)

## Overview

This guide uses two main MC-Terrarium APIs:

1. **Testbed API** — Creates infrastructure (VPC, subnet, router, VM, etc.) in AWS and DCS
2. **AWS-to-Site VPN API** — Establishes a VPN tunnel between AWS VPN Gateway and DCS (OpenStack) VPN service

The overall workflow is:

```
Create Terrarium → Create Testbed → Create VPN → Test Ping → Delete VPN → Delete Testbed → Delete Terrarium
```

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        VPN Connection (IPsec)                        │
│                                                                      │
│   ┌─────────────────────┐              ┌─────────────────────┐       │
│   │       AWS            │   VPN Tunnel │       DCS            │       │
│   │                     │◄────────────►│  (OpenStack)         │       │
│   │  ┌──────────────┐  │              │  ┌──────────────┐   │       │
│   │  │  VPC          │  │              │  │  Network     │   │       │
│   │  │  10.0.0.0/16  │  │              │  │  10.6.0.0/24 │   │       │
│   │  │  ┌─────────┐ │  │              │  │  ┌─────────┐│   │       │
│   │  │  │  EC2 VM  │ │  │              │  │  │  VM     ││   │       │
│   │  │  │(Private) │ │  │              │  │  │(Private)││   │       │
│   │  │  └─────────┘ │  │              │  │  └─────────┘│   │       │
│   │  └──────────────┘  │              │  └──────────────┘   │       │
│   │  ┌──────────────┐  │              │  ┌──────────────┐   │       │
│   │  │ VPN Gateway   │  │              │  │ VPN Service  │   │       │
│   │  └──────────────┘  │              │  └──────────────┘   │       │
│   └─────────────────────┘              └─────────────────────┘       │
└──────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### 1. Credential Preparation

You need valid credentials for **AWS** and **DCS (OpenStack)**. Credentials are loaded from `~/.cloud-barista/secrets/` by the docker-compose configuration.

#### AWS Credential

Create the file `~/.cloud-barista/secrets/credentials`:

```ini
[default]
AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
```

> Refer to [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-methods) for details.

#### DCS (OpenStack) Credential

Create the file `~/.cloud-barista/secrets/credential-dcs.env`:

```dotenv
OS_USERNAME=YOUR_OPENSTACK_USERNAME
OS_PROJECT_NAME=YOUR_PROJECT_NAME
OS_PASSWORD=YOUR_PASSWORD
OS_AUTH_URL=http://YOUR_OPENSTACK_AUTH_URL:5000/v3
OS_REGION_NAME=RegionOne
```

> The `OS_AUTH_URL` should point to your OpenStack Keystone endpoint.

#### Verify Credential Files Exist

```bash
ls -la ~/.cloud-barista/secrets/credentials
ls -la ~/.cloud-barista/secrets/credential-dcs.env
```

> **Note:** Other CSP credential files (Azure, GCP, Alibaba, IBM, NCP) referenced in `docker-compose.yaml` must also exist even if empty, or you can comment them out in `docker-compose.yaml`. For this guide, only AWS and DCS credentials are required.

### 2. System Launch via make compose

```bash
cd ~/dev/cloud-barista/mc-terrarium

# Build and start MC-Terrarium (builds container image and starts the service)
make compose
```

The API server will be available at `http://localhost:8055`.

You can verify it by accessing the Swagger API dashboard: http://localhost:8055/terrarium/api/index.html

> **Note:** The default API authentication uses Basic Auth with username `default` and password `default`. All curl commands in this guide include `-u default:default`.

> **Tip:** You can append `| jq .` to the end of any curl command to pretty-print JSON responses. (Requires `jq`: `sudo apt install jq` or `brew install jq`)

---

## Step-by-Step Guide

### Step 1: Health Check

Verify the MC-Terrarium service is running:

```bash
curl -s -u default:default http://localhost:8055/terrarium/readyz
```

Expected response:

```
OK
```

### Step 2: Create a Terrarium for Testbed

Create a terrarium to manage the testbed infrastructure:

```bash
curl -s -X POST -u default:default \
  http://localhost:8055/terrarium/tr \
  -H "Content-Type: application/json" \
  -d '{
    "name": "testbed01",
    "description": "Testbed for AWS-DCS VPN connectivity test"
  }'
```

Expected response:

```json
{
  "id": "testbed01",
  "name": "testbed01",
  "description": "Testbed for AWS-DCS VPN connectivity test",
  "enrichments": "",
  "providers": []
}
```

### Step 3: Create the Testbed (AWS + DCS)

Create a testbed with VMs in both AWS and DCS. This step provisions VPC, subnets, security groups, VMs, etc. in each cloud.

> **⏱ This may take 3-5 minutes** as it creates infrastructure resources in both AWS and DCS.

```bash
curl -s -X POST -u default:default \
  http://localhost:8055/terrarium/tr/testbed01/testbed \
  -H "Content-Type: application/json" \
  -d '{
    "testbed_config": {
      "terrarium_id": "testbed01",
      "desired_providers": ["aws", "dcs"]
    }
  }'
```

Expected response (abbreviated):

```json
{
  "success": true,
  "message": "successfully applied the infrastructure terrarium",
  "detail": "..."
}
```

### Step 4: Get Testbed Information

Retrieve the created testbed resources. You will need `vpc_id`, `subnet_id`, `router_id`, etc. for the VPN setup.

```bash
curl -s -X GET -u default:default \
  http://localhost:8055/terrarium/tr/testbed01/testbed
```

Expected response (example):

```json
{
  "success": true,
  "message": "successfully got the infrastructure terrarium output",
  "detail": {
    "aws_testbed_info": {
      "vpc_id": "vpc-0abc1234def56789",
      "vpc_cidr": "10.0.0.0/16",
      "subnet_id": "subnet-0abc1234def56789",
      "subnet_cidr": "10.0.1.0/24",
      "public_ip": "y.y.y.y",
      "private_ip": "10.0.1.xxx"
    },
    "dcs_testbed_info": {
      "vpc_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "subnet_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "router_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "vm_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "public_ip": "x.x.x.x",
      "private_ip": "10.6.0.x"
    }
  }
}
```

**Save the key values for VPN setup.**

From the response above, note the following values. You will need them in Step 6 and Step 8.

| Value            | JSON Path                             | Example                                |
| ---------------- | ------------------------------------- | -------------------------------------- |
| `AWS_VPC_ID`     | `.detail.aws_testbed_info.vpc_id`     | `vpc-0abc1234def56789`                 |
| `AWS_SUBNET_ID`  | `.detail.aws_testbed_info.subnet_id`  | `subnet-0abc1234def56789`              |
| `AWS_PUBLIC_IP`  | `.detail.aws_testbed_info.public_ip`  | `y.y.y.y`                              |
| `AWS_PRIVATE_IP` | `.detail.aws_testbed_info.private_ip` | `10.0.1.xxx`                           |
| `DCS_ROUTER_ID`  | `.detail.dcs_testbed_info.router_id`  | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `DCS_SUBNET_ID`  | `.detail.dcs_testbed_info.subnet_id`  | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `DCS_PUBLIC_IP`  | `.detail.dcs_testbed_info.public_ip`  | `x.x.x.x`                              |
| `DCS_PRIVATE_IP` | `.detail.dcs_testbed_info.private_ip` | `10.6.0.x`                             |

### Step 5: Create a Terrarium for VPN

Create a separate terrarium for the VPN resources:

```bash
curl -s -X POST -u default:default \
  http://localhost:8055/terrarium/tr \
  -H "Content-Type: application/json" \
  -d '{
    "name": "vpn-aws-dcs-01",
    "description": "AWS-to-DCS VPN connection"
  }'
```

### Step 6: Create AWS-to-DCS VPN Connection

Create the VPN connection between AWS and DCS using the resource IDs obtained from the testbed.

> **⏱ This may take 5-10 minutes** as it creates VPN gateway, customer gateway, VPN connections, and DCS VPN service resources.

> **Important:** Replace `<AWS_VPC_ID>`, `<AWS_SUBNET_ID>`, `<DCS_ROUTER_ID>`, `<DCS_SUBNET_ID>` with the actual values obtained in Step 4.

```bash
curl -s -X POST -u default:default \
  http://localhost:8055/terrarium/tr/vpn-aws-dcs-01/vpn/aws-to-site \
  -H "Content-Type: application/json" \
  -d '{
    "vpn_config": {
      "terrarium_id": "vpn-aws-dcs-01",
      "aws": {
        "region": "ap-northeast-2",
        "vpc_id": "<AWS_VPC_ID>",
        "subnet_id": "<AWS_SUBNET_ID>"
      },
      "target_csp": {
        "type": "dcs",
        "dcs": {
          "router_id": "<DCS_ROUTER_ID>",
          "subnet_id": "<DCS_SUBNET_ID>"
        }
      }
    }
  }'
```

Expected response:

```json
{
  "success": true,
  "message": "successfully applied the infrastructure terrarium",
  "detail": "..."
}
```

### Step 7: Get VPN Connection Information

Verify the VPN connection was created successfully:

```bash
curl -s -X GET -u default:default \
  http://localhost:8055/terrarium/tr/vpn-aws-dcs-01/vpn/aws-to-site
```

Expected response (example):

```json
{
  "success": true,
  "message": "successfully got the infrastructure terrarium output",
  "detail": {
    "terrarium": {
      "id": "vpn-aws-dcs-01"
    },
    "aws": {
      "vpn_gateway": {
        "resource_type": "VPN Gateway",
        "name": "vpn-aws-dcs-01-vpn-gw",
        "id": "vgw-xxxx",
        "vpc_id": "vpc-xxxx"
      },
      "customer_gateways": [...],
      "vpn_connections": [...]
    },
    "dcs": {
      "vpn_service": {
        "resource_type": "VPN Service",
        "name": "vpn-aws-dcs-01-vpn-service",
        "id": "xxxx",
        "router_id": "xxxx",
        "external_ip": "x.x.x.x"
      },
      "site_connections": [...]
    }
  }
}
```

> **Note:** It may take a few minutes after VPN creation for the tunnels to fully establish. Wait 2-3 minutes before proceeding to the connectivity test.

### Step 8: Connectivity Test (Ping)

Test network connectivity between the AWS EC2 instance and the DCS VM through the VPN tunnel by pinging the **private IP** addresses.

#### Preparation: Get the SSH Private Key

Before SSH-ing into either VM, extract the SSH private key from the testbed:

```bash
curl -s -X GET -u default:default \
  "http://localhost:8055/terrarium/tr/testbed01/testbed?detail=raw" \
  | jq -r '.list[] | select(.type == "tls_private_key") | .values.private_key_pem' > /tmp/testbed-key.pem
chmod 600 /tmp/testbed-key.pem
```

#### Option A: SSH into the DCS VM and ping the AWS VM

```bash
# Replace <DCS_PUBLIC_IP> and <AWS_PRIVATE_IP> with actual values from Step 4
ssh -i /tmp/testbed-key.pem -o StrictHostKeyChecking=no ubuntu@<DCS_PUBLIC_IP> \
  "ping -c 5 <AWS_PRIVATE_IP>"
```

Expected output (when VPN is working):

```
PING 10.0.1.xxx (10.0.1.xxx) 56(84) bytes of data.
64 bytes from 10.0.1.xxx: icmp_seq=1 ttl=62 time=xx.x ms
64 bytes from 10.0.1.xxx: icmp_seq=2 ttl=62 time=xx.x ms
64 bytes from 10.0.1.xxx: icmp_seq=3 ttl=62 time=xx.x ms
64 bytes from 10.0.1.xxx: icmp_seq=4 ttl=62 time=xx.x ms
64 bytes from 10.0.1.xxx: icmp_seq=5 ttl=62 time=xx.x ms

--- 10.0.1.xxx ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4005ms
```

#### Option B: SSH into the AWS VM and ping the DCS VM

```bash
# Replace <AWS_PUBLIC_IP> and <DCS_PRIVATE_IP> with actual values from Step 4
ssh -i /tmp/testbed-key.pem -o StrictHostKeyChecking=no ubuntu@<AWS_PUBLIC_IP> \
  "ping -c 5 <DCS_PRIVATE_IP>"
```

> **Tip:** If ping fails immediately, the VPN tunnel may not be fully established yet. Wait 2-3 more minutes and try again. VPN tunnel negotiation happens on-demand in some cases.

### Step 9: Delete VPN Connection

After testing, delete the VPN connection:

> **⏱ This may take 3-5 minutes** to destroy VPN resources.

```bash
curl -s -X DELETE -u default:default \
  http://localhost:8055/terrarium/tr/vpn-aws-dcs-01/vpn/aws-to-site
```

Expected response:

```json
{
  "success": true,
  "message": "successfully destroyed the infrastructure terrarium",
  "detail": "..."
}
```

### Step 10: Delete VPN Terrarium

```bash
curl -s -X DELETE -u default:default \
  http://localhost:8055/terrarium/tr/vpn-aws-dcs-01
```

### Step 11: Delete the Testbed

Delete all testbed resources (VMs, VPCs, subnets, etc.):

> **⏱ This may take 3-5 minutes** to destroy testbed resources in both AWS and DCS.

```bash
curl -s -X DELETE -u default:default \
  http://localhost:8055/terrarium/tr/testbed01/testbed
```

Expected response:

```json
{
  "success": true,
  "message": "successfully destroyed the infrastructure terrarium",
  "detail": "..."
}
```

### Step 12: Delete Testbed Terrarium

```bash
curl -s -X DELETE -u default:default \
  http://localhost:8055/terrarium/tr/testbed01
```

---

## Troubleshooting

### VPN Tunnel Not Establishing

- **Wait longer:** VPN tunnel negotiation may take up to 5 minutes after creation.
- **Check VPN status:** Use `GET /tr/{trId}/vpn/aws-to-site?detail=raw` for detailed raw output including tunnel status.
- **Security groups:** Ensure the testbed security groups allow ICMP (ping) traffic. The default testbed templates include ICMP rules.

### Ping Fails with "Destination Host Unreachable"

- The VPN tunnel may not be fully active. Wait and retry.
- Verify the VPN connection was created successfully (Step 7).
- Check that route propagation is enabled on the AWS side (this is handled automatically by the template).

### SSH Connection Refused

- Ensure the VM has finished booting (wait 1-2 minutes after testbed creation).
- Verify the security group allows SSH (port 22) — included by default in testbed templates.
- Check that the public IP is correctly extracted.

### Credential Errors

- Verify AWS credentials are valid: `aws sts get-caller-identity`
- Verify DCS (OpenStack) credentials: `openstack token issue` (if OpenStack CLI is available)
- Ensure credential files are in `~/.cloud-barista/secrets/` with correct filenames.

### API Returns 401 Unauthorized

- Ensure you include the `-u default:default` authentication flag in curl commands.
- If you changed the password, update the `-u` flag accordingly.

### Testbed or VPN Creation Times Out

- Check the MC-Terrarium container logs: `docker logs mc-terrarium -f`
- Ensure network connectivity from the container to AWS and DCS endpoints.

---

## Notes

### Resource Costs

- **AWS:** Creating a VPN Gateway incurs hourly charges. The EC2 instance (t3.micro) also incurs charges. Make sure to complete the cleanup steps to avoid unexpected costs.
- **DCS:** Resource costs depend on your OpenStack/DCS provider's pricing model.

### Separate Terrariums for Testbed and VPN

This guide uses **separate terrariums** for the testbed and VPN. This is recommended because:

- Each terrarium manages its own OpenTofu state independently.
- The VPN can be created/destroyed without affecting the testbed.
- It follows the principle of infrastructure isolation.

### Using Low-Level APIs for Debugging

If the high-level API (e.g., `POST /tr/{trId}/vpn/aws-to-site`) fails, you can use the low-level action APIs for step-by-step debugging:

```bash
# Step-by-step VPN creation
# 1. Init (copies templates and initializes OpenTofu)
curl -s -X POST -u default:default \
  http://localhost:8055/terrarium/tr/vpn-aws-dcs-01/vpn/aws-to-site/actions/init \
  -H "Content-Type: application/json" \
  -d '{ ... }'

# 2. Plan (shows what resources will be created)
curl -s -X POST -u default:default \
  http://localhost:8055/terrarium/tr/vpn-aws-dcs-01/vpn/aws-to-site/actions/plan

# 3. Apply (actually creates the resources)
curl -s -X POST -u default:default \
  http://localhost:8055/terrarium/tr/vpn-aws-dcs-01/vpn/aws-to-site/actions/apply

# Check output
curl -s -X GET -u default:default \
  http://localhost:8055/terrarium/tr/vpn-aws-dcs-01/vpn/aws-to-site/actions/output
```

Similarly, for step-by-step deletion:

```bash
# 1. Destroy
curl -s -X DELETE -u default:default \
  http://localhost:8055/terrarium/tr/vpn-aws-dcs-01/vpn/aws-to-site/actions/destroy

# 2. EmptyOut (clean up workspace)
curl -s -X DELETE -u default:default \
  http://localhost:8055/terrarium/tr/vpn-aws-dcs-01/vpn/aws-to-site/actions/emptyout
```

### Swagger API Dashboard

For interactive API exploration, access the Swagger UI:

```
http://localhost:8055/terrarium/api/index.html
```

This provides a visual interface to explore all available APIs, including request/response schemas.
