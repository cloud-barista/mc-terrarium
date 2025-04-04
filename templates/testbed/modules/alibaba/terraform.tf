# providers.tf
terraform {
  required_version = ">=1.8.3"

  required_providers {
    # Alibaba Cloud provider
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~>1.243.0"
    }
  }
}
