# Configure the IBM Cloud Provider
provider "ibm" {
  region = try(var.vpn_config.target_csp.ibm.region, "au-syd") # Default: "au-syd",  Sydney region, Australia
}
