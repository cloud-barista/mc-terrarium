# Outputs wrapped in SqlDbInstanceInfo object, including public IP
output "sql_db_info" {
  value = {
    instance_name   = google_sql_database_instance.instance.name
    database_name   = google_sql_database.engine.name
    database_user   = google_sql_user.admin_user.name
    connection_name = google_sql_database_instance.instance.connection_name
    public_ip       = google_sql_database_instance.instance.public_ip_address
  }
  description = "Information for SQL Database instance, including instance name, database name, user, connection name, and public IP address"
}
