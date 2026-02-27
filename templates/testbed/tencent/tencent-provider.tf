# Read Tencent Cloud credentials from OpenBao
data "vault_kv_secret_v2" "tencent" {
  mount = "secret"
  name  = "csp/tencent"
}

# Configure the Tencent Cloud Provider
provider "tencentcloud" {
  region     = "ap-seoul" # Default: "ap-seoul", Seoul region, Korea
  secret_id  = data.vault_kv_secret_v2.tencent.data["TENCENTCLOUD_SECRET_ID"]
  secret_key = data.vault_kv_secret_v2.tencent.data["TENCENTCLOUD_SECRET_KEY"]
}
