## Configure the IBM Cloud Provider

terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.76.0"
    }
  }
}

provider "ibm" {
  region = "jp-tok" # Tokyo, Japan
}

resource "ibm_is_vpc" "example_vpc" {
  name = "terraform-example-vpc"
  tags = ["terraform-101"]
}

resource "ibm_is_vpc_address_prefix" "example_prefix" {
  name = "terraform-example-prefix"
  vpc  = ibm_is_vpc.example_vpc.id
  zone = "${var.region}-1"
  cidr = "10.240.0.0/18"
}

resource "ibm_is_subnet" "example_subnet" {
  name            = "terraform-example-subnet"
  vpc             = ibm_is_vpc.example_vpc.id
  zone            = "${var.region}-1" # e.g., kr-seo
  ipv4_cidr_block = "10.240.0.0/24"

  depends_on = [ibm_is_vpc_address_prefix.example_prefix]
}

# Output
output "vpc_info" {
  description = "Details of the created VPC"
  value = {
    id   = ibm_is_vpc.example_vpc.id
    name = ibm_is_vpc.example_vpc.name
    tags = ibm_is_vpc.example_vpc.tags
  }
}

output "subnet_info" {
  description = "Details of the created Subnet"
  value = {
    id         = ibm_is_subnet.example_subnet.id
    vpc_id     = ibm_is_subnet.example_subnet.vpc
    cidr_block = ibm_is_subnet.example_subnet.ipv4_cidr_block
    zone       = ibm_is_subnet.example_subnet.zone
  }
}
