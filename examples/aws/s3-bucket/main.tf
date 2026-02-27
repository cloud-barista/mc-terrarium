# Required OpenTofu and provider versions
terraform {
  required_version = ">=1.8.3"

  required_providers {
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

# Create VPC
# Note: Using a /16 CIDR block allows for future subnet expansion
resource "aws_vpc" "tofu_example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tofu-example"
  }
}

# Create a subnet
# Note: Single subnet is sufficient for S3 access via VPC endpoint
# Note: S3 is a regional service, so it is not necessary to create a bucket in each availability zone.
resource "aws_subnet" "tofu_example" {
  vpc_id            = aws_vpc.tofu_example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "tofu-example-subnet"
  }
}

# Create Internet Gateway
# Note: Required for internet access from the VPC
resource "aws_internet_gateway" "tofu_example" {
  vpc_id = aws_vpc.tofu_example.id

  tags = {
    Name = "tofu-example-igw"
  }
}

# Create route table
resource "aws_route_table" "tofu_example" {
  vpc_id = aws_vpc.tofu_example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tofu_example.id
  }

  tags = {
    Name = "tofu-example-rt"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "tofu_example" {
  subnet_id      = aws_subnet.tofu_example.id
  route_table_id = aws_route_table.tofu_example.id
}

# Create S3 bucket
# Note: S3 buckets must have globally unique names
# Note: S3 automatically provides cross-AZ redundancy
resource "aws_s3_bucket" "tofu_example" {
  bucket = "my-unique-bucket-name-2024102216" # Replace with your own unique bucket name

  tags = {
    Name        = "Tofu-Example-Bucket"
    Environment = "Dev"
  }
}

# Enable versioning for S3 bucket
# Note: Versioning cannot be disabled once enabled, only suspended
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tofu_example.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure server-side encryption for S3 bucket
# Note: AES256 is the default AWS managed encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.tofu_example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to S3 bucket
# Note: This is a security best practice for most use cases
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.tofu_example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create VPC Endpoint for S3
# Note: Gateway endpoint is free and provides secure access to S3 from VPC
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.tofu_example.id
  service_name = "com.amazonaws.ap-northeast-2.s3" # Fixed value of S3 service name for ap-northeast-2 

  tags = {
    Name = "s3-endpoint"
  }
}

# Associate VPC Endpoint with route table
resource "aws_vpc_endpoint_route_table_association" "s3_endpoint" {
  route_table_id  = aws_route_table.tofu_example.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

# Additional Notes:
# - S3 is a regional service that doesn't require multi-AZ subnet configuration
# - VPC Endpoint provides secure access to S3 without internet gateway
# - Bucket names must be globally unique across all AWS accounts
# - The configuration includes security best practices like encryption and public access blocking
