terraform {

  # Required Tofu version
  required_version = "~>1.8.3"

  required_providers {
    ncloud = {
      source  = "NaverCloudPlatform/ncloud"
      version = "3.2.1"
    }
  }
}

provider "ncloud" {
  access_key  = var.ncloud_access_key
  secret_key  = var.ncloud_secret_key
  region      = "KR" # Set the desired region (e.g., "KR", "JP", etc.)
  support_vpc = true # Enable VPC support
}

# Declare variables
variable "ncloud_access_key" {
  description = "Naver Cloud Platform Access Key"
  type        = string
  default     = "" # Leave the default value empty
}

variable "ncloud_secret_key" {
  description = "Naver Cloud Platform Secret Key"
  type        = string
  default     = "" # Leave the default value empty
}

# Declare MongoDB admin user
variable "mongodb_user_name" {
  description = "MongoDB admin username"
  type        = string
  default     = "dbadmin" # 기본 관리자 사용자명
}

# Declare MongoDB admin password
variable "mongodb_user_password" {
  description = "MongoDB admin password"
  type        = string
  sensitive   = true        # 민감 정보로 표시
  default     = "P@ssw0rd!" # 기본 관리자 비밀번호
}

# Create VPC
resource "ncloud_vpc" "example" {
  name            = "tofu-vpc-mongodb"
  ipv4_cidr_block = "10.0.0.0/16" # CIDR block for the VPC
}

# Create Network ACL
resource "ncloud_network_acl" "nacl" {
  vpc_no = ncloud_vpc.example.id
}

# Create Subnet
resource "ncloud_subnet" "example" {
  name           = "tofu-subnet-mongodb"
  vpc_no         = ncloud_vpc.example.vpc_no
  subnet         = cidrsubnet(ncloud_vpc.example.ipv4_cidr_block, 8, 0) # "10.0.0.0/24" CIDR block for the subnet
  zone           = "KR-1"                                               # Availability zone
  network_acl_no = ncloud_vpc.example.default_network_acl_no            # Network ACL number
  subnet_type    = "PUBLIC"                                             # Subnet type
}

# Create MongoDB instance
resource "ncloud_mongodb" "mongodb" {
  vpc_no             = ncloud_vpc.example.id
  subnet_no          = ncloud_subnet.example.id
  service_name       = "tofu-mongodb"
  server_name_prefix = "tf-svr"
  user_name          = var.mongodb_user_name     # Admin username (variable used)
  user_password      = var.mongodb_user_password # Admin password (variable used)
  cluster_type_code  = "STAND_ALONE"
}
