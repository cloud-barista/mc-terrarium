variable "vpn_config" {
  description = "VPN configuration for multi-cloud site-to-site connections"
  type = object({
    terrarium_id  = string
    shared_secret = optional(string, "MySharedSecret123!")
    aws = optional(object({
      region    = optional(string, "ap-northeast-2") # Seoul
      vpc_id    = string
      subnet_id = string
      bgp_asn   = optional(string, "64512") # default value
    }))
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

      # BGP peering CIDR ranges for Azure connections to other CSPs
      bgp_peering_cidrs = optional(object({
        # APIPA CIDRs for connection to AWS
        to_aws = optional(list(string), [
          "169.254.21.0/30", # Tunnel 1 - Interface 0
          "169.254.21.4/30", # Tunnel 1 - Interface 1  
          "169.254.22.0/30", # Tunnel 2 - Interface 0
          "169.254.22.4/30"  # Tunnel 2 - Interface 1
        ])

        # APIPA CIDRs for connection to GCP
        to_gcp = optional(list(string), [
          "169.254.23.0/30", # Tunnel 1 - Interface 0
          "169.254.23.4/30", # Tunnel 1 - Interface 1
          "169.254.24.0/30", # Tunnel 2 - Interface 0  
          "169.254.24.4/30"  # Tunnel 2 - Interface 1
        ])

        # APIPA CIDRs for connection to Alibaba Cloud
        to_alibaba = optional(list(string), [
          "169.254.25.0/30", # Tunnel 1 - Interface 0
          "169.254.25.4/30", # Tunnel 1 - Interface 1
          "169.254.26.0/30", # Tunnel 2 - Interface 0
          "169.254.26.4/30"  # Tunnel 2 - Interface 1
        ])

        # APIPA CIDRs for connection to Tencent Cloud
        to_tencent = optional(list(string), [
          "169.254.27.0/30", # Tunnel 1 - Interface 0
          "169.254.27.4/30", # Tunnel 1 - Interface 1
          "169.254.28.0/30", # Tunnel 2 - Interface 0
          "169.254.28.4/30"  # Tunnel 2 - Interface 1
        ])

        # APIPA CIDRs for connection to IBM Cloud
        to_ibm = optional(list(string), [
          "169.254.29.0/30", # Tunnel 1 - Interface 0
          "169.254.29.4/30", # Tunnel 1 - Interface 1
          "169.254.30.0/30", # Tunnel 2 - Interface 0
          "169.254.30.4/30"  # Tunnel 2 - Interface 1
        ])
        }), {
        # Default values if not specified
        to_aws = [
          "169.254.21.0/30", "169.254.21.4/30",
          "169.254.22.0/30", "169.254.22.4/30"
        ]
        to_gcp = [
          "169.254.23.0/30", "169.254.23.4/30",
          "169.254.24.0/30", "169.254.24.4/30"
        ]
        to_alibaba = [
          "169.254.25.0/30", "169.254.25.4/30",
          "169.254.26.0/30", "169.254.26.4/30"
        ]
        to_tencent = [
          "169.254.27.0/30", "169.254.27.4/30",
          "169.254.28.0/30", "169.254.28.4/30"
        ]
        to_ibm = [
          "169.254.29.0/30", "169.254.29.4/30",
          "169.254.30.0/30", "169.254.30.4/30"
        ]
      })
    }))
    alibaba = optional(object({
      region       = optional(string, "ap-northeast-2") # Seoul
      vpc_id       = string
      vswitch_id_1 = string                    # Add this field
      vswitch_id_2 = string                    # Add this field
      bgp_asn      = optional(string, "65532") # default value
    }))
    tencent = optional(object({
      region = optional(string, "ap-seoul") # Seoul region
      vpc_id = string
      # subnet_id = string
      # bgp_asn   = optional(string, "65534") # default value
    }))
    ibm = optional(object({
      region    = optional(string, "au-syd") # Sydney region
      vpc_id    = string
      vpc_cidr  = string
      subnet_id = string
      # bgp_asn   = optional(string, "65533") # default value
    }))
  })

  # validation {
  #   condition = (
  #     var.vpn_config.target_csp.type == "gcp" ? var.vpn_config.target_csp.gcp != null :
  #     var.vpn_config.target_csp.type == "azure" ? var.vpn_config.target_csp.azure != null :
  #     var.vpn_config.target_csp.type == "alibaba" ? var.vpn_config.target_csp.alibaba != null :
  #     var.vpn_config.target_csp.type == "tencent" ? var.vpn_config.target_csp.tencent != null :
  #     var.vpn_config.target_csp.type == "ibm" ? var.vpn_config.target_csp.ibm != null : false
  #   )
  #   error_message = "Configuration for the selected CSP must be provided"
  # }
}
