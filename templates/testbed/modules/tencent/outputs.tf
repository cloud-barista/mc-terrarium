# outputs.tf
output "testbed_info" {
  value = {
    vpc_id      = tencentcloud_vpc.main.id
    vpc_cidr    = tencentcloud_vpc.main.cidr_block
    subnet_id   = tencentcloud_subnet.main.id
    subnet_cidr = tencentcloud_subnet.main.cidr_block
  }
}

output "ssh_info" {
  sensitive = true
  value = {
    public_ip  = tencentcloud_instance.main.public_ip
    private_ip = tencentcloud_instance.main.private_ip
    user       = "ubuntu"
    command    = "ssh -i private_key.pem ubuntu@${tencentcloud_instance.main.public_ip}"
  }
}
