# Read OpenStack/DCS credentials from OpenBao
data "vault_kv_secret_v2" "openstack" {
  mount = "secret"
  name  = "csp/openstack"
}

# Configure OpenStack Provider (DCS)
provider "openstack" {
  auth_url    = data.vault_kv_secret_v2.openstack.data["OS_AUTH_URL"]
  user_name   = data.vault_kv_secret_v2.openstack.data["OS_USERNAME"]
  password    = data.vault_kv_secret_v2.openstack.data["OS_PASSWORD"]
  domain_name = data.vault_kv_secret_v2.openstack.data["OS_DOMAIN_NAME"]
  tenant_name = data.vault_kv_secret_v2.openstack.data["OS_PROJECT_NAME"]
}
