## Configure the AliCloud Provider

terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.243.0"
    }
  }
}

provider "alicloud" {
  region = "ap-northeast-2"
}

# Create a new ECS instance for VPC
resource "alicloud_vpc" "example_vpc" {
  cidr_block = "172.16.0.0/16"
  tags = {
    Name = "terraform-101"
  }
}

data "alicloud_zones" "default" {
  available_resource_creation = "VSwitch"
}

resource "alicloud_vswitch" "example_vswitch" {
  vpc_id     = alicloud_vpc.example_vpc.id
  cidr_block = "172.16.0.0/24"
  zone_id    = data.alicloud_zones.default.zones.0.id
}

# Output
output "vpc_info" {
  description = "Details of the created VPC"
  value = {
    id         = alicloud_vpc.example_vpc.id
    cidr_block = alicloud_vpc.example_vpc.cidr_block
    tags       = alicloud_vpc.example_vpc.tags
  }
}

output "vswitch_info" {
  description = "Details of the created VSwitch"
  value = {
    id         = alicloud_vswitch.example_vswitch.id
    vpc_id     = alicloud_vswitch.example_vswitch.vpc_id
    cidr_block = alicloud_vswitch.example_vswitch.cidr_block
    zone_id    = alicloud_vswitch.example_vswitch.zone_id
  }
}

output "zone_info" {
  description = "The selected Availability Zone"
  value       = data.alicloud_zones.default.zones.0.id
}
