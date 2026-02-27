## CSP Credentials

This directory previously held CSP credential files used directly by OpenTofu templates.

> [!IMPORTANT]
> MC-Terrarium now uses **OpenBao** (Vault-compatible) for centralized credential management.
> CSP credentials are stored in OpenBao KV v2 (`secret/csp/{provider}`) and accessed
> at runtime via the `hashicorp/vault` provider — no credential files are copied to working directories.

### Setup

For credential setup instructions, see [init/README.md](../init/README.md).

**Quick summary:**

1. Prepare `~/.cloud-barista/credentials.yaml` (from [CB-Tumblebug template](https://github.com/cloud-barista/cb-tumblebug/tree/main/init))
2. Encrypt it with `encCredential.sh`
3. Run `bash init/init.sh` — this decrypts and registers credentials into OpenBao

### Legacy Files

The credential template files below are kept for reference but are **no longer used** by templates or the application at runtime:

| File                              | CSP       | Status |
| --------------------------------- | --------- | ------ |
| `template-credentials`            | AWS       | Legacy |
| `template-azure.env`              | Azure     | Legacy |
| `template-credential-gcp.json`    | GCP       | Legacy |
| `template-credential-alibaba.env` | Alibaba   | Legacy |
| `template-credential-ibm.env`     | IBM       | Legacy |
| `template-credential-ncp.env`     | NCP       | Legacy |
| `template-credential-dcs.env`     | OpenStack | Legacy |
| `template-credential-tencent.env` | Tencent   | Legacy |

### CSP Credential Reference

Below is a reference for preparing CSP credentials. Once prepared, add them to `~/.cloud-barista/credentials.yaml`.

#### AWS

Prepare your AWS credential (Access Key ID and Secret Access Key).

See [Set and view configuration settings using commands](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-methods)

#### Azure

Prepare an Azure service principal (Client ID, Client Secret, Tenant ID, Subscription ID).

See [Create an Azure service principal with Azure CLI](https://learn.microsoft.com/en-us/cli/azure/azure-cli-sp-tutorial-1?tabs=bash)

#### GCP

Prepare a GCP service account key (JSON format).

See [Service account credentials](https://developers.google.com/workspace/guides/create-credentials#service-account)

#### Alibaba Cloud

Prepare your Alibaba Cloud credential on Resource Access Management (RAM).

See [Alibaba Cloud RAM](https://www.alibabacloud.com/help/en/ram/)

#### IBM Cloud

Prepare your IBM Cloud API key (My Page > Manage > Access (IAM) > API Key).

#### NCP (Naver Cloud Platform)

Prepare your NCP API authentication key (My Page > Manage Auth Key).

#### Tencent Cloud

Prepare your Tencent Cloud API key (Secret ID and Secret Key).

See [Tencent Cloud CAM](https://www.tencentcloud.com/document/product/598)

#### OpenStack / DCS

Prepare your OpenStack credentials (Auth URL, Username, Password, Domain Name, Project Name).
