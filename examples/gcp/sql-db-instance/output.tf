# Outputs wrapped in SqlDbInstanceInfo object, including public IP
output "SqlDbInstanceInfo" {
  value = {
    instance_name   = google_sql_database_instance.my_sql_instance.name
    database_name   = google_sql_database.my_database.name
    database_user   = google_sql_user.my_user.name
    connection_name = google_sql_database_instance.my_sql_instance.connection_name
    public_ip       = google_sql_database_instance.my_sql_instance.public_ip_address
  }
  description = "Information for SQL Database instance, including instance name, database name, user, connection name, and public IP address"
}
