# Define the required version of Terraform and the providers that will be used in the project
terraform {
  # Required OpenTofu version
  required_version = "~>1.8.3"

  required_providers {
    # AWS provider is specified with its source and version from OpenTofu registry
    aws = {
      source  = "registry.opentofu.org/hashicorp/aws"
      version = "~>5.42"
    }
  }
}

# Provider block for AWS specifies the configuration for the provider
provider "aws" {
  region = "ap-northeast-2"
}

# Create a security group for RDS Database Instance
resource "aws_security_group" "rds_sg" {
  name = "rds_sg"
  
  ingress {
    description = "Allow MySQL traffic"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Consider restricting this for security
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 allows all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_sg"
  }
}

# Create an RDS Database Instance with updated instance class and engine version
resource "aws_db_instance" "myinstance" {
  engine               = "mysql"
  identifier           = "myrdsinstance"
  allocated_storage    = 20
  engine_version       = "8.0.39"  # Use a compatible version of MySQL
  instance_class       = "db.t3.micro"  # Updated to a supported instance class
  username             = "myrdsuser"
  password             = "myrdspassword"
  parameter_group_name = "default.mysql8.0"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
  publicly_accessible  = true

  tags = {
    Name = "myrdsinstance"
  }
}