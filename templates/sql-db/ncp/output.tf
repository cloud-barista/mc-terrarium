output "sql_db_info" {
  description = "Information needed to connect to the MySQL RDS instance."
  value = {
    terrarium = {
      id = var.terrarium_id
    }
    ncp = {
      instance_identifier = ncloud_mysql.mysql.service_name
      connection_info     = ncloud_mysql.mysql.host_ip
      admin_username      = ncloud_mysql.mysql.user_name
      database_name       = ncloud_mysql.mysql.database_name
      port                = 3306                      # var.db_engine_port
      region              = ncloud_mysql.mysql.region // Assume region is available
    }
  }
  # sensitive = true // Mark as sensitive to hide sensitive details like passwords
}
