# Create SQL MySQL instance
resource "google_sql_database_instance" "instance" {
  name             = "${var.terrarium_id}-db-instance"
  database_version = var.db_engine_version # Specify the MySQL version you need, such as MYSQL_8_0
  # region           = "us-central1"

  settings {
    tier = var.db_instance_spec # Set the instance type, such as db-f1-micro
  }

  # deletion_protection = false # Disable deletion protection
}

# Create database
resource "google_sql_database" "engine" {
  name     = "${var.terrarium_id}-db-engine"
  instance = google_sql_database_instance.instance.name
}

# Create user (optional)
resource "google_sql_user" "admin_user" {
  instance = google_sql_database_instance.instance.name
  name     = var.db_admin_username
  password = var.db_admin_username # Set a strong password
}
