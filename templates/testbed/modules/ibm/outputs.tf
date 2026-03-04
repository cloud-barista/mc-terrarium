# outputs.tf
output "testbed_info" {
  value = {
    vpc_id      = ibm_is_vpc.main.id
    vpc_crn     = ibm_is_vpc.main.crn # The VPC CRN (Cloud Resource Name) to provide DNS server addresses for this VPC
    vpc_cidr    = var.vpc_cidr         # Logical VPC CIDR managed by operator (for VPN routing)
    subnet_id   = ibm_is_subnet.main.id
    subnet_cidr = ibm_is_subnet.main.ipv4_cidr_block
    private_ip  = ibm_is_instance.main.primary_network_interface[0].primary_ip[0].address
  }
}
output "ssh_info" {
  sensitive = true
  value = {
    public_ip  = ibm_is_floating_ip.main.address
    private_ip = ibm_is_instance.main.primary_network_interface[0].primary_ip[0].address
    user       = "ubuntu"
    command    = "ssh -i private_key.pem ubuntu@${ibm_is_floating_ip.main.address}"
  }
}
