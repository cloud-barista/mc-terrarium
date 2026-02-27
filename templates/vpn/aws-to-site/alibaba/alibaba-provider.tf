# Read Alibaba Cloud credentials from OpenBao
data "vault_kv_secret_v2" "alibaba" {
  mount = "secret"
  name  = "csp/alibaba"
}

# Configure the Alibaba Cloud Provider
provider "alicloud" {
  region     = try(var.vpn_config.target_csp.alibaba.region, "ap-northeast-2") # Default: "ap-northeast-2", Seoul region, Korea
  access_key = data.vault_kv_secret_v2.alibaba.data["ALIBABA_CLOUD_ACCESS_KEY_ID"]
  secret_key = data.vault_kv_secret_v2.alibaba.data["ALIBABA_CLOUD_ACCESS_KEY_SECRET"]
}
