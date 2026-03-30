# Read OpenStack/DCS credentials from OpenBao
data "vault_kv_secret_v2" "openstack" {
  mount = "secret"
  name  = var.credential_profile == "admin" ? "csp/openstack" : "users/${var.credential_profile}/csp/openstack"
}

# Configure OpenStack Provider (DCS)
provider "openstack" {
  auth_url    = data.vault_kv_secret_v2.openstack.data["OS_AUTH_URL"]
  user_name   = data.vault_kv_secret_v2.openstack.data["OS_USERNAME"]
  password    = data.vault_kv_secret_v2.openstack.data["OS_PASSWORD"]
  domain_name = data.vault_kv_secret_v2.openstack.data["OS_DOMAIN_NAME"]
  tenant_id   = data.vault_kv_secret_v2.openstack.data["OS_PROJECT_ID"]
}
