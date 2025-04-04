# Configure the AWS Provider
provider "aws" {
  region = try(var.vpn_config.aws.region, "ap-northeast-2") # Default: "ap-northeast-2", Seoul region, Korea
}

# [NOTE]
# Ref.) Azure Provider: Authenticating using a Service Principal with a Client Secret
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret

# Configure the Microsoft Azure Provider
provider "azurerm" {
  # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  skip_provider_registration = true
  features {}
}

# Configure GCP Provider
provider "google" {
  credentials = file("credential-gcp.json")
  project     = jsondecode(file("credential-gcp.json")).project_id
  region      = try(var.vpn_config.target_csp.gcp.region, "asia-northeast3") # Default: "asia-northeast3", Seoul region, Korea
}

# Configure the Alibaba Cloud Provider
provider "alicloud" {
  region = try(var.vpn_config.target_csp.alibaba.region, "ap-northeast-2") # Default: "ap-northeast-2", Seoul region, Korea
}

# Configure the Tencent Cloud Provider
provider "tencentcloud" {
  region = try(var.vpn_config.target_csp.tencent.region, "ap-seoul") # Default: "ap-seoul", Seoul region, Korea
}

# Configure the IBM Cloud Provider
provider "ibm" {
  region = try(var.vpn_config.target_csp.ibm.region, "au-syd") # Default: "au-syd",  Sydney region, Australia
}
