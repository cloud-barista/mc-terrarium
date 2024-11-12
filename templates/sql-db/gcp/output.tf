output "sql_db_info" {
  value = {
    terrarium = {
      id = var.terrarium_id
    }
    gcp = {
      instance_identifier = google_sql_database_instance.instance.name
      database_name       = google_sql_database.engine.name
      admin_username      = google_sql_user.admin_user.name
      connection_info     = google_sql_database_instance.instance.connection_name
      ip_address          = google_sql_database_instance.instance.public_ip_address
      port                = 3306 # var.db_engine_port
      region              = google_sql_database_instance.instance.region
    }
  }
  description = "Information for SQL Database instance, including instance name, database name, user, connection name, and public IP address"
}
