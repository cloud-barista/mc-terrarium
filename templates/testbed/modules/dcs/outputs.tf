output "info" {
  value = {
    vpc_id     = openstack_networking_network_v2.main.id
    subnet_id  = openstack_networking_subnet_v2.main.id
    router_id  = openstack_networking_router_v2.main.id
    vm_id      = openstack_compute_instance_v2.main.id
    public_ip  = openstack_networking_floatingip_v2.main.address
    private_ip = openstack_compute_instance_v2.main.access_ip_v4
  }
}
