output "sql_db_info" {
  description = "Information needed to connect to the MySQL RDS instance."
  value = {
    service_name       = ncloud_mysql.mysql.service_name
    server_name_prefix = ncloud_mysql.mysql.server_name_prefix
    user_name          = ncloud_mysql.mysql.user_name
    host_ip            = ncloud_mysql.mysql.host_ip
    database_name      = ncloud_mysql.mysql.database_name
    # user_password      = ncloud_mysql.mysql.user_password
  }
  # sensitive = true // Mark as sensitive to hide sensitive details like passwords
}
