
resource "azurerm_mysql_flexible_server" "instance" {
  name                = "${var.terrarium_id}-db-instance"
  location            = var.csp_region
  resource_group_name = var.csp_resource_group

  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password

  sku_name = var.db_instance_spec # e.g., General Purpose, Standard_D2s_v3
  # storage_mb = 5120              # 5 GB
  version = var.db_engine_version # MySQL version (e.g., "5.7", "8.0")

  # storage_auto_grow             = "Enabled"
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  # public_network_access_enabled = true

  # Commented out the undeclared resource reference
  # delegated_subnet_id = azurerm_subnet.example.id
}

resource "azurerm_mysql_flexible_database" "engine" {
  name                = "${var.terrarium_id}-db-engine"
  resource_group_name = var.csp_resource_group
  server_name         = azurerm_mysql_flexible_server.instance.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}
