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
        # APIPA CIDRs for connection to AWS (2 in .21.x, 2 in .22.x)
        to_aws = optional(list(string), [
          "169.254.21.0/30", # AWS Connection 1 - .21 subnet
          "169.254.21.4/30", # AWS Connection 2 - .21 subnet
          "169.254.22.0/30", # AWS Connection 3 - .22 subnet
          "169.254.22.4/30"  # AWS Connection 4 - .22 subnet
        ])

        # APIPA CIDRs for connection to GCP (2 in .21.x, 2 in .22.x)
        to_gcp = optional(list(string), [
          "169.254.21.8/30",  # GCP Connection 1 - .21 subnet
          "169.254.21.12/30", # GCP Connection 2 - .21 subnet
          "169.254.22.8/30",  # GCP Connection 3 - .22 subnet
          "169.254.22.12/30"  # GCP Connection 4 - .22 subnet
        ])

        # APIPA CIDRs for connection to Alibaba Cloud (2 in .21.x, 2 in .22.x)
        to_alibaba = optional(list(string), [
          "169.254.21.16/30", # Alibaba Connection 1 - .21 subnet
          "169.254.21.20/30", # Alibaba Connection 2 - .21 subnet
          "169.254.22.16/30", # Alibaba Connection 3 - .22 subnet
          "169.254.22.20/30"  # Alibaba Connection 4 - .22 subnet
        ])

        # APIPA CIDRs for connection to Tencent Cloud (2 in .21.x, 2 in .22.x)
        to_tencent = optional(list(string), [
          "169.254.21.24/30", # Tencent Connection 1 - .21 subnet
          "169.254.21.28/30", # Tencent Connection 2 - .21 subnet
          "169.254.22.24/30", # Tencent Connection 3 - .22 subnet
          "169.254.22.28/30"  # Tencent Connection 4 - .22 subnet
        ])

        # APIPA CIDRs for connection to IBM Cloud (2 in .21.x, 2 in .22.x)
        to_ibm = optional(list(string), [
          "169.254.21.32/30", # IBM Connection 1 - .21 subnet
          "169.254.21.36/30", # IBM Connection 2 - .21 subnet
          "169.254.22.32/30", # IBM Connection 3 - .22 subnet
          "169.254.22.36/30"  # IBM Connection 4 - .22 subnet
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
      vswitch_id_1 = string                    # Primary VSwitch (required)
      vswitch_id_2 = optional(string)          # Disaster recovery VSwitch (optional)
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
