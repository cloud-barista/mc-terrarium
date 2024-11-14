
# Create MySQL RDS Instance
resource "ncloud_mysql" "mysql" {
  subnet_no          = var.csp_subnet1_id
  service_name       = "${var.terrarium_id}-svc" # Service name: Only English alphabets, numbers, dash ( - ) and Korean letters can be entered. Min: 3, Max: 30
  server_name_prefix = "svr-name-prefix"         # Server name prefix: In order to prevent overlapping host names, random text is added. Min: 3, Max: 20
  user_name          = var.db_admin_username     # Master username
  user_password      = var.db_admin_password     # Master password
  host_ip            = "%"                       # Host IP: "%" For overall access (use cautiously), specific IPs permitted: 1.1.1.1, IP band connection permitted: 1.1.1.%
  database_name      = "${var.terrarium_id}-db"  # Initial database name
}
