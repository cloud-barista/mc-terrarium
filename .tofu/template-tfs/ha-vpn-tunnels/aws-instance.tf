
resource "aws_instance" "my-aws-instance" {
  ami           = "ami-0f3a440bbcff3d043" # Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.my-aws-sg.id]

  # subnet_id = aws_subnet.my-aws-subnet-2.id
  subnet_id = var.my-imported-aws-subnet-id

  tags = {
    Name = "my-aws-instance"
  }
}