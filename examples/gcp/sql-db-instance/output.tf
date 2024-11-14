# Outputs wrapped in sql_db_info object
output "sql_db_info" {
  description = "Information of the MySQL Cloud SQL instance in GCP."
  value = {
    sql_db_detail = {
      # Basic Information
      instance_name        = google_sql_database_instance.my_sql_instance.name                                    # "my-sql-instance"
      instance_resource_id = google_sql_database_instance.my_sql_instance.id                                      # "my-sql-instance"
      instance_spec        = google_sql_database_instance.my_sql_instance.settings[0].tier                        # "db-f1-micro"
      location             = google_sql_database_instance.my_sql_instance.settings[0].location_preference[0].zone # "asia-northeast3-a"
      tags                 = google_sql_database_instance.my_sql_instance.settings[0].user_labels                 # {}

      # Storage Configuration
      storage_type = google_sql_database_instance.my_sql_instance.settings[0].disk_type # "PD_SSD"
      storage_size = google_sql_database_instance.my_sql_instance.settings[0].disk_size # 10

      # Database Engine Information
      engine_name    = "mysql"                                                       # Not exposed by GCP
      engine_version = google_sql_database_instance.my_sql_instance.database_version # "MYSQL_8_0"

      # Database Connection Details
      connection_endpoint   = "${google_sql_database_instance.my_sql_instance.first_ip_address}:3306"
      connection_host       = google_sql_database_instance.my_sql_instance.first_ip_address
      connection_port       = 3306 # Default MySQL port
      public_access_enabled = google_sql_database_instance.my_sql_instance.settings[0].ip_configuration[0].ipv4_enabled

      # Authentication
      admin_username = google_sql_user.my_user.name     # "myuser"
      # admin_password = google_sql_user.my_user.password # "mypassword"

      provider_specific_detail = {
        provider            = "gcp"
        resource_identifier = google_sql_database_instance.my_sql_instance.self_link
        availability_type   = google_sql_database_instance.my_sql_instance.settings[0].availability_type

        project = google_sql_database_instance.my_sql_instance.project
        region  = google_sql_database_instance.my_sql_instance.region
      }
    }
  }
}

# output "my_sql_instance_all" {
#   description = "All information"
#   value       = google_sql_database_instance.my_sql_instance
#   sensitive   = true
# }

# output "my_database_all" {
#   description = "All information"
#   value       = google_sql_database.my_database
#   sensitive   = true
# }

# output "my_user_all" {
#   description = "All information"
#   value       = google_sql_user.my_user
#   sensitive   = true
# }
