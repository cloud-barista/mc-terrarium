# Configure the Tencent Cloud Provider
provider "tencentcloud" {
  region = try(var.vpn_config.target_csp.tencent.region, "ap-seoul") # Default: "ap-seoul", Seoul region, Korea
}
