# Security Group
# Private EC2 SG
resource "aws_security_group" "my-aws-sg"{
  name        = "my-aws-sg"
  description = "for private ec2"
  vpc_id      = aws_vpc.my-aws-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-aws-private-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-icmp" {  
  security_group_id = aws_security_group.my-aws-sg.id  
  cidr_ipv4 = "0.0.0.0/0"
  from_port = -1
  to_port = -1
  ip_protocol = "icmp"
  description = "Allow all incoming ICMP"
}
