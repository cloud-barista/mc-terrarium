# Create a DB subnet group 
resource "aws_db_subnet_group" "rds" {
  name       = "main"
  subnet_ids = [var.csp_subnet1_id, var.csp_subnet2_id]

  tags = {
    Name = "${var.terrarium_id} My DB subnet group"
  }
}


# Create a security group for RDS Database Instance
resource "aws_security_group" "rds_sg" {
  name   = "${var.terrarium_id}-rds-sg"
  vpc_id = var.csp_vnet_id

  ingress {
    description = "Allow MySQL traffic"
    from_port   = var.db_engine_port
    to_port     = var.db_engine_port
    protocol    = "tcp"
    cidr_blocks = [var.ingress_cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidr_block]
  }

  tags = {
    Name = "${var.terrarium_id}-rds-sg"
  }
}

# Create an RDS Database Instance with updated instance class and engine version
resource "aws_db_instance" "db_instance" {
  engine               = "mysql"
  identifier           = "${var.terrarium_id}-db-instance"
  allocated_storage    = 20
  engine_version       = var.db_engine_version # Use a compatible version of MySQL
  instance_class       = var.db_instance_spec  # Updated to a supported instance class
  username             = var.db_admin_username
  password             = var.db_admin_password
  parameter_group_name = "default.mysql8.0"

  db_subnet_group_name   = aws_db_subnet_group.rds.name # Use the created DB subnet group
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true
  publicly_accessible = true

  tags = {
    Name = "${var.terrarium_id}-db-instance"
  }
}

