# Configure the AWS Provider
provider "aws" {
  region = try(var.vpn_config.aws.region, "ap-northeast-2") # Default: "ap-northeast-2", Seoul region, Korea
}
