# outputs.tf
output "testbed_info" {
  value = {
    vpc_id      = aws_vpc.main.id
    vpc_cidr    = aws_vpc.main.cidr_block
    subnet_id   = aws_subnet.main.id
    subnet_cidr = aws_subnet.main.cidr_block
    public_ip   = aws_eip.main.public_ip
    private_ip  = aws_instance.main.private_ip
  }
}

output "ssh_info" {
  sensitive = true
  value = {
    public_ip  = aws_eip.main.public_ip
    private_ip = aws_instance.main.private_ip
    user       = "ubuntu"
    command    = "ssh -i private_key.pem ubuntu@${aws_eip.main.public_ip}"
  }
}
