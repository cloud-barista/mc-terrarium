# Configure the Alibaba Cloud Provider
provider "alicloud" {
  region = try(var.vpn_config.target_csp.alibaba.region, "ap-northeast-2") # Default: "ap-northeast-2", Seoul region, Korea
}
