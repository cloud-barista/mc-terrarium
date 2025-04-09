# IBM module
module "ibm" {
  source = "./modules/ibm"

  # Input variables
  name_prefix = var.vpn_config.terrarium_id
  region      = var.vpn_config.target_csp.ibm.region
  vpc_id      = var.vpn_config.target_csp.ibm.vpc_id
  vpc_cidr    = var.vpn_config.target_csp.ibm.vpc_cidr
  subnet_id   = var.vpn_config.target_csp.ibm.subnet_id
  # bgp_asn       = var.vpn_config.target_csp.ibm.bgp_asn


  # AWS resource
  aws_vpn_gateway_id = aws_vpn_gateway.vpn_gw.id
  aws_vpc_cidr_block = data.aws_vpc.existing.cidr_block
}
