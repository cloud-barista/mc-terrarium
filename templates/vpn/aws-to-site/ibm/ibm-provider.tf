# Read IBM Cloud credentials from OpenBao
data "vault_kv_secret_v2" "ibm" {
  mount = "secret"
  name  = "csp/ibm"
}

# Configure the IBM Cloud Provider
provider "ibm" {
  region           = try(var.vpn_config.target_csp.ibm.region, "au-syd") # Default: "au-syd",  Sydney region, Australia
  ibmcloud_api_key = data.vault_kv_secret_v2.ibm.data["IC_API_KEY"]
}
