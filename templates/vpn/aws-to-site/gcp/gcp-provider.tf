# Read GCP credentials from OpenBao
data "vault_kv_secret_v2" "gcp" {
  mount = "secret"
  name  = "csp/gcp"
}

# Reconstruct GCP credential JSON from OpenBao KV data
locals {
  gcp_credential = jsonencode({
    type                        = "service_account"
    project_id                  = data.vault_kv_secret_v2.gcp.data["project_id"]
    private_key_id              = data.vault_kv_secret_v2.gcp.data["private_key_id"]
    private_key                 = replace(data.vault_kv_secret_v2.gcp.data["private_key"], "\\n", "\n")
    client_email                = data.vault_kv_secret_v2.gcp.data["client_email"]
    client_id                   = data.vault_kv_secret_v2.gcp.data["client_id"]
    auth_uri                    = "https://accounts.google.com/o/oauth2/auth"
    token_uri                   = "https://oauth2.googleapis.com/token"
    auth_provider_x509_cert_url = "https://www.googleapis.com/oauth2/v1/certs"
    client_x509_cert_url        = "https://www.googleapis.com/robot/v1/metadata/x509/${urlencode(data.vault_kv_secret_v2.gcp.data["client_email"])}"
  })
}

# Configure GCP Provider
provider "google" {
  credentials = local.gcp_credential
  project     = data.vault_kv_secret_v2.gcp.data["project_id"]
  region      = try(var.vpn_config.target_csp.gcp.region, "asia-northeast3") # Default: "asia-northeast3", Seoul region, Korea
}
