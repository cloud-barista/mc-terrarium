# Output Values for VPN Connection Information

# AWS Outputs
output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.main.id
}

output "aws_vpc_cidr" {
  description = "AWS VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "aws_vpn_gateway_id" {
  description = "AWS VPN Gateway ID"
  value       = aws_vpn_gateway.vgw.id
}

output "aws_customer_gateway_ids" {
  description = "AWS Customer Gateway IDs"
  value = {
    tunnel_1 = aws_customer_gateway.cgw.id
    tunnel_2 = aws_customer_gateway.cgw.id
  }
}

output "aws_vpn_connection_id" {
  description = "AWS VPN Connection IDs"
  value = {
    connection_1 = aws_vpn_connection.to_dcs.id
    connection_2 = aws_vpn_connection.to_dcs.id
  }
}

output "aws_vpn_connection_tunnels" {
  description = "AWS VPN Connection tunnel details"
  value = {
    connection_1_tunnel_1 = {
      address            = aws_vpn_connection.to_dcs.tunnel1_address
      bgp_asn            = aws_vpn_connection.to_dcs.tunnel1_bgp_asn
      bgp_holdtime       = aws_vpn_connection.to_dcs.tunnel1_bgp_holdtime
      inside_cidr        = aws_vpn_connection.to_dcs.tunnel1_inside_cidr
      vgw_inside_address = aws_vpn_connection.to_dcs.tunnel1_vgw_inside_address
      cgw_inside_address = aws_vpn_connection.to_dcs.tunnel1_cgw_inside_address
      preshared_key      = aws_vpn_connection.to_dcs.tunnel1_preshared_key
    }
    connection_1_tunnel_2 = {
      address            = aws_vpn_connection.to_dcs.tunnel2_address
      bgp_asn            = aws_vpn_connection.to_dcs.tunnel2_bgp_asn
      bgp_holdtime       = aws_vpn_connection.to_dcs.tunnel2_bgp_holdtime
      inside_cidr        = aws_vpn_connection.to_dcs.tunnel2_inside_cidr
      vgw_inside_address = aws_vpn_connection.to_dcs.tunnel2_vgw_inside_address
      cgw_inside_address = aws_vpn_connection.to_dcs.tunnel2_cgw_inside_address
      preshared_key      = aws_vpn_connection.to_dcs.tunnel2_preshared_key
    }
    connection_2_tunnel_1 = {
      address            = aws_vpn_connection.to_dcs.tunnel1_address
      bgp_asn            = aws_vpn_connection.to_dcs.tunnel1_bgp_asn
      bgp_holdtime       = aws_vpn_connection.to_dcs.tunnel1_bgp_holdtime
      inside_cidr        = aws_vpn_connection.to_dcs.tunnel1_inside_cidr
      vgw_inside_address = aws_vpn_connection.to_dcs.tunnel1_vgw_inside_address
      cgw_inside_address = aws_vpn_connection.to_dcs.tunnel1_cgw_inside_address
      preshared_key      = aws_vpn_connection.to_dcs.tunnel1_preshared_key
    }
    connection_2_tunnel_2 = {
      address            = aws_vpn_connection.to_dcs.tunnel2_address
      bgp_asn            = aws_vpn_connection.to_dcs.tunnel2_bgp_asn
      bgp_holdtime       = aws_vpn_connection.to_dcs.tunnel2_bgp_holdtime
      inside_cidr        = aws_vpn_connection.to_dcs.tunnel2_inside_cidr
      vgw_inside_address = aws_vpn_connection.to_dcs.tunnel2_vgw_inside_address
      cgw_inside_address = aws_vpn_connection.to_dcs.tunnel2_cgw_inside_address
      preshared_key      = aws_vpn_connection.to_dcs.tunnel2_preshared_key
    }
  }
  sensitive = true
}

output "aws_instance_info" {
  description = "AWS test instance information"
  value = {
    id         = aws_instance.test.id
    private_ip = aws_instance.test.private_ip
    public_ip  = aws_instance.test.public_ip
  }
}

# DCS Outputs
output "openstack_network_id" {
  description = "DCS network ID"
  value       = openstack_networking_network_v2.main.id
}

output "openstack_subnet_id" {
  description = "DCS subnet ID"
  value       = openstack_networking_subnet_v2.main.id
}

output "openstack_router_id" {
  description = "DCS router ID"
  value       = openstack_networking_router_v2.main.id
}

output "openstack_vpn_service_id" {
  description = "DCS VPNaaS service ID"
  value       = openstack_vpnaas_service_v2.vpn.id
}

output "openstack_vpn_service_external_ip" {
  description = "DCS VPNaaS service external IP"
  value       = openstack_vpnaas_service_v2.vpn.external_v4_ip
}

output "openstack_site_connections" {
  description = "DCS VPN site connection details"
  value = {
    tunnel_1 = {
      id = openstack_vpnaas_site_connection_v2.to_aws1.id
    }
    tunnel_2 = {
      id = openstack_vpnaas_site_connection_v2.to_aws2.id
    }
  }
}

output "openstack_instance_info" {
  description = "OpenStack test instance information"
  value = {
    id          = openstack_compute_instance_v2.test.id
    name        = openstack_compute_instance_v2.test.name
    private_ip  = openstack_compute_instance_v2.test.access_ip_v4
    floating_ip = openstack_networking_floatingip_v2.test.address
  }
}

# VPN Connection Summary
output "vpn_connection_summary" {
  description = "VPN connection summary"
  value = {
    aws_vpn_gateway_id       = aws_vpn_gateway.vgw.id
    openstack_vpn_service_ip = openstack_vpnaas_service_v2.vpn.external_v4_ip
    tunnel_count             = 2
    shared_secret            = "*** HIDDEN ***"
    aws_network              = var.aws_vpc_cidr
    openstack_network        = var.openstack_network_cidr
  }
}

# SSH Key Information (Shared between AWS and OpenStack)
output "ssh_private_key_pem" {
  description = "Private SSH key for accessing instances (use 'tofu output -raw ssh_private_key_pem > key.pem')"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "ssh_public_key" {
  description = "Public SSH key (shared between AWS and OpenStack)"
  value       = tls_private_key.ssh.public_key_openssh
}

output "key_pair_name" {
  description = "Key pair name (same for both AWS and OpenStack)"
  value       = "${var.name_prefix}-key"
}

output "aws_key_pair_name" {
  description = "AWS key pair name"
  value       = aws_key_pair.main.key_name
}

output "openstack_key_pair_name" {
  description = "OpenStack key pair name"
  value       = openstack_compute_keypair_v2.main.name
}
