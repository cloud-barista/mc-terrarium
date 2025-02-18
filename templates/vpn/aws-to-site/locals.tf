locals {
  is_gcp     = var.vpn_config.target_csp.type == "gcp"
  is_azure   = var.vpn_config.target_csp.type == "azure"
  is_alibaba = var.vpn_config.target_csp.type == "alibaba"
  is_tencent = var.vpn_config.target_csp.type == "tencent"
  is_ibm     = var.vpn_config.target_csp.type == "ibm"

  # a local variable to reference CSP config easily
  csp_config = (
    local.is_gcp ? var.vpn_config.target_csp.gcp :
    local.is_azure ? var.vpn_config.target_csp.azure :
    local.is_alibaba ? var.vpn_config.target_csp.alibaba :
    local.is_tencent ? var.vpn_config.target_csp.tencent :
    local.is_ibm ? var.vpn_config.target_csp.ibm : null
  )

  name_prefix = var.vpn_config.terrarium_id
}
