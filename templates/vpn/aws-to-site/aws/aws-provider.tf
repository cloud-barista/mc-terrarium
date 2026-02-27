# Read AWS credentials from OpenBao
data "vault_kv_secret_v2" "aws" {
  mount = "secret"
  name  = "csp/aws"
}

# Configure the AWS Provider
provider "aws" {
  region     = try(var.vpn_config.aws.region, "ap-northeast-2") # Default: "ap-northeast-2", Seoul region, Korea
  access_key = data.vault_kv_secret_v2.aws.data["AWS_ACCESS_KEY_ID"]
  secret_key = data.vault_kv_secret_v2.aws.data["AWS_SECRET_ACCESS_KEY"]
}
