output "testbed_info" {
  value = {
    vpc_id         = alicloud_vpc.main.id
    vpc_cidr       = alicloud_vpc.main.cidr_block
    vswitch_1_id   = alicloud_vswitch.main.id
    vswitch_1_cidr = alicloud_vswitch.main.cidr_block
    vswitch_2_id   = alicloud_vswitch.secondary.id
    vswitch_2_cidr = alicloud_vswitch.secondary.cidr_block
  }
}

output "ssh_info" {
  sensitive = true
  value = {
    public_ip  = alicloud_instance.main.public_ip
    private_ip = alicloud_instance.main.private_ip
    user       = "ubuntu"
    command    = "ssh -i private_key.pem ubuntu@${alicloud_instance.main.public_ip}"
  }
}
