# providers.tf
terraform {
  required_version = ">=1.8.3"

  required_providers {
    # Tencent Cloud provider
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "~>1.81.173"
    }
  }
}
