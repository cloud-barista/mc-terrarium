variable "vpn_config" {
  description = "VPN configuration for AWS and target CSP connection"
  type = object({
    terrarium_id = string
    aws = object({
      region    = optional(string, "ap-northeast-2") # Seoul
      vpc_id    = string
      subnet_id = string
    })
    target_csp = object({
      type = string # "gcp", "azure", "alibaba", "tencent", "ibm"
      gcp = optional(object({
        region           = optional(string, "asia-northeast3") # Seoul
        vpc_network_name = string
        bgp_asn          = optional(string, "65530") # default value
      }))
      azure = optional(object({
        region               = string
        resource_group_name  = string
        virtual_network_name = string
        gateway_subnet_cidr  = string
        bgp_asn              = optional(string, "65531") # default value
        vpn_sku              = optional(string, "VpnGw1AZ")
        shared_key           = string
      }))
      alibaba = optional(object({
        region  = string
        vpc_id  = string
        bgp_asn = string
      }))
      tencent = optional(object({
        region  = string
        vpc_id  = string
        bgp_asn = string
      }))
      ibm = optional(object({
        region   = string
        vpc_name = string
        bgp_asn  = string
      }))
    })
  })

  validation {
    condition     = contains(["gcp", "azure", "alibaba", "tencent", "ibm"], var.vpn_config.target_csp.type)
    error_message = "Target CSP type must be one of: gcp, azure, alibaba, tencent, ibm"
  }

  validation {
    condition = (
      var.vpn_config.target_csp.type == "gcp" ? var.vpn_config.target_csp.gcp != null :
      var.vpn_config.target_csp.type == "azure" ? var.vpn_config.target_csp.azure != null :
      var.vpn_config.target_csp.type == "alibaba" ? var.vpn_config.target_csp.alibaba != null :
      var.vpn_config.target_csp.type == "tencent" ? var.vpn_config.target_csp.tencent != null :
      var.vpn_config.target_csp.type == "ibm" ? var.vpn_config.target_csp.ibm != null : false
    )
    error_message = "Configuration for the selected CSP must be provided"
  }
}
