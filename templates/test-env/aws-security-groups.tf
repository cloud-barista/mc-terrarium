# Define a security group
# Private EC2 SG
resource "aws_security_group" "test_sg"{
  name        = "tr-aws-sg"
  description = "for private ec2"
  vpc_id      = aws_vpc.test_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tr-aws-sg"
  }
}

# Define a security group rule
resource "aws_vpc_security_group_ingress_rule" "test_rule_allow_icmp" {  
  security_group_id = aws_security_group.test_sg.id  
  cidr_ipv4 = "0.0.0.0/0"
  from_port = -1
  to_port = -1
  ip_protocol = "icmp"
  description = "Allow all incoming ICMP"
}