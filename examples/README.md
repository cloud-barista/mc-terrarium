# MC-Terrarium Examples

OpenTofu examples for provisioning cloud resources across multiple CSPs.

All examples use **OpenBao** (Vault-compatible) for centralized credential management — no hardcoded secrets or environment variable exports needed.

## Prerequisites

See [OpenBao & Credential Initialization](../deployments/docker-compose/openbao/README.md) for instructions on setting up OpenBao and registering CSP credentials.

Once OpenBao is running and credentials are registered, set the environment variables in your terminal session:

```bash
# Export VAULT_ADDR and VAULT_TOKEN
source .env
```

## Usage

From any example directory:

```bash
cd examples/aws/basic    # (or any other example)
tofu init
tofu plan
tofu apply
tofu destroy
```

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
