output "sql_db_info" {
  value = {
    terrarium = {
      id = var.terrarium_id
    }
    aws = {
      instance_identifier = aws_db_instance.db_instance.identifier
      connection_info     = aws_db_instance.db_instance.endpoint
      port                = var.db_engine_port
      admin_username      = aws_db_instance.db_instance.username
      database_engine     = aws_db_instance.db_instance.engine
      engine_version      = aws_db_instance.db_instance.engine_version
      region              = var.csp_region
      vpc_id              = var.csp_vnet_id
      subnet_ids          = [var.csp_subnet1_id, var.csp_subnet2_id]
      security_group_name = "${var.terrarium_id}-rds-sg"
    }
  }
  description = "Information for connecting to the MySQL RDS instance with dynamic variables."
}
