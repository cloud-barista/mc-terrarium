output "sql_db_info" {
  value = {
    db_instance_identifier = aws_db_instance.db_instance.identifier
    db_instance_endpoint   = aws_db_instance.db_instance.endpoint
    db_instance_port       = aws_db_instance.db_instance.port
    db_instance_username   = aws_db_instance.db_instance.username
    db_instance_engine     = aws_db_instance.db_instance.engine
    db_instance_version    = aws_db_instance.db_instance.engine_version
    db_instance_vpc_id     = var.csp_vnet_id
    db_instance_subnet_ids = [var.csp_subnet1_id, var.csp_subnet2_id]
    db_security_group_name = "${var.terrarium_id}-rds-sg"
  }

  description = "Information for connecting to the MySQL RDS instance with dynamic variables."
}
