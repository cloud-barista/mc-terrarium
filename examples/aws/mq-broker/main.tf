# Define the required version of OpenTofu and the providers that will be used in the project
terraform {
  # Required OpenTofu version
  required_version = ">=1.8.3"

  required_providers {
    # AWS provider is specified with its source and version
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }
    # Vault provider for OpenBao credential access
    vault = {
      source  = "registry.opentofu.org/hashicorp/vault"
      version = "~>4.0"
    }
  }
}

# ── OpenBao Provider (Vault-compatible) ───────────────────────────
# Reads VAULT_ADDR and VAULT_TOKEN from environment variables.
provider "vault" {}

# ── Read AWS credentials from OpenBao ─────────────────────────────
data "vault_kv_secret_v2" "aws" {
  mount = "secret"
  name  = "csp/aws"
}

# ── AWS Provider using OpenBao credentials ────────────────────────
provider "aws" {
  region     = "ap-northeast-2"
  access_key = data.vault_kv_secret_v2.aws.data["AWS_ACCESS_KEY_ID"]
  secret_key = data.vault_kv_secret_v2.aws.data["AWS_SECRET_ACCESS_KEY"]
}


# Define the VPC resource block
resource "aws_vpc" "tofu_example" {
  cidr_block = "192.168.64.0/22"

  tags = {
    Name = "tofu-101"
  }
}

# Amazon MQ Broker (ActiveMQ)
resource "aws_mq_broker" "tofu_example" {
  broker_name    = "tofu-broker"
  engine_type    = "ActiveMQ" # RabbitMQ is also available
  engine_version = "5.17.6"   # Valid values: [5.18, 5.17.6, 5.16.7]
  # auto_minor_version_upgrade = true       # Brokers on [ActiveMQ] version [5.18] must have [autoMinorVersionUpgrade] set to [true]
  host_instance_type  = "mq.t3.micro"
  publicly_accessible = true

  user {
    username = "admin"
    password = "examplepassword"
  }
}

# Security Group for Amazon MQ
resource "aws_security_group" "mq_sg" {
  name_prefix = "tofu-mq-sg-"
  description = "MQ Broker Security Group"
  vpc_id      = aws_vpc.tofu_example.id

  ingress {
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Output Broker Information
output "amazon_mq_broker_info" {
  value = {
    broker_id       = aws_mq_broker.tofu_example.id
    broker_endpoint = aws_mq_broker.tofu_example.instances[0].endpoints[0]
    security_group  = aws_security_group.mq_sg.id
  }
}

output "all_vpc_info" {
  value = aws_vpc.tofu_example
}


output "all_security_group_info" {
  value = aws_security_group.mq_sg
}

output "all_mq_broker_info" {
  value     = aws_mq_broker.tofu_example
  sensitive = true
}
