output "wg_server_info" {
  description = "Information about the WireGuard server instance"
  value = {
    id                 = aws_instance.wg-server.id
    private_ip         = aws_instance.wg-server.private_ip
    public_ip          = aws_instance.wg-server.public_ip
    availability_zone  = aws_instance.wg-server.availability_zone
    subnet_id          = aws_instance.wg-server.subnet_id
    security_group_ids = aws_instance.wg-server.vpc_security_group_ids
    instance_type      = aws_instance.wg-server.instance_type
    volume_size        = aws_instance.wg-server.root_block_device[0].volume_size
  }
}

output "secure_server_info" {
  description = "Information about the secure server instance"
  value = {
    id                 = aws_instance.secure-server.id
    private_ip         = aws_instance.secure-server.private_ip
    public_ip          = aws_instance.secure-server.public_ip # Will be null for private subnet
    availability_zone  = aws_instance.secure-server.availability_zone
    subnet_id          = aws_instance.secure-server.subnet_id
    security_group_ids = aws_instance.secure-server.vpc_security_group_ids
    instance_type      = aws_instance.secure-server.instance_type
    volume_size        = aws_instance.secure-server.root_block_device[0].volume_size
  }
}
