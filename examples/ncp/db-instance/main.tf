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

# variable "server_image_product_code" {
#   description = "Product code for the image to use (e.g., 'SPSW0LINUX000046')"
#   default     = "SPSW0LINUX000046" # Example: Ubuntu 20.04 LTS
# }

# variable "server_spec_code" {
#   description = "Product code for the server specification (e.g., 'SVR.VSV2.C004.M002.NET.SSD.B050.G002')"
#   default     = "SVR.VSV2.C004.M002.NET.SSD.B050.G002" # Example: 2 vCPU, 4GB RAM
# }

#Server Image Type & Product Type
data "ncloud_server_image" "server_image" {
  filter {
    name   = "product_name"
    values = ["ubuntu-20.04"]
  }
  # image list
  #  + "SW.VSVR.OS.LNX64.CNTOS.0703.B050"          = "centos-7.3-64"
  #  + "SW.VSVR.OS.LNX64.CNTOS.0708.B050"          = "CentOS 7.8 (64-bit)"
  #  + "SW.VSVR.OS.LNX64.UBNTU.SVR1604.B050"         = "ubuntu-16.04-64-server"
  #  + "SW.VSVR.OS.LNX64.UBNTU.SVR1804.B050"         = "ubuntu-18.04"
  #  + "SW.VSVR.OS.LNX64.UBNTU.SVR2004.B050"         = "ubuntu-20.04"
  #  + "SW.VSVR.OS.WND64.WND.SVR2016EN.B100"         = "Windows Server 2016 (64-bit) English Edition"
  #  + "SW.VSVR.OS.WND64.WND.SVR2019EN.B100"         = "Windows Server 2019 (64-bit) English Edition"

  # Attributes Reference
  # data.ncloud_server_image.server_image.id
}
data "ncloud_server_product" "product" {
  server_image_product_code = data.ncloud_server_image.server_image.id

  filter {
    name   = "product_code"
    values = ["SSD"]
    regex  = true
  }
  filter {
    name   = "cpu_count"
    values = ["2"]
  }
  filter {
    name   = "memory_size"
    values = ["4GB"]
  }
  filter {
    name   = "product_type"
    values = ["HICPU"]
    # Server Spec Type
    # STAND
    # HICPU
    # HIMEM
  }
  # Attributes Reference
  # data.ncloud_server_product.product.id
}


variable "login_key_name" {
  default = "tofu-example-key"
}

resource "random_id" "id" {
  byte_length = 4
}

resource "ncloud_login_key" "key" {
  key_name = "${var.login_key_name}${random_id.id.hex}"
}

# Create VPC
resource "ncloud_vpc" "example" {
  name            = "tofu-example-vpc"
  ipv4_cidr_block = "10.0.0.0/16" # CIDR block for the VPC

}

# Create Network ACL
resource "ncloud_network_acl" "nacl" {
  vpc_no = ncloud_vpc.example.id
}

# Create Subnet
resource "ncloud_subnet" "example" {
  name           = "tofu-example-subnet"
  vpc_no         = ncloud_vpc.example.vpc_no
  subnet         = cidrsubnet(ncloud_vpc.example.ipv4_cidr_block, 8, 0) # "10.0.0.0/24" CIDR block for the subnet
  zone           = "KR-1"                                               # Availability zone
  network_acl_no = ncloud_vpc.example.default_network_acl_no            # Network ACL number
  subnet_type    = "PUBLIC"                                             # Subnet type
}

# Create MySQL RDS Instance
resource "ncloud_mysql" "mysql" {
  subnet_no          = ncloud_subnet.example.id
  service_name       = "tofu-example-mysql"      # Service name: Only English alphabets, numbers, dash ( - ) and Korean letters can be entered. Min: 3, Max: 30
  server_name_prefix = "tofu-example-prefix"     # Server name prefix
  user_name          = "username"                # Master username
  user_password      = "password1!"              # Master password
  host_ip            = "%"                       # Host IP: "%" For overall access (use cautiously), specific IPs permitted: 1.1.1.1, IP band connection permitted: 1.1.1.%
  database_name      = "tofu-example-initial-db" # Initial database name
}
