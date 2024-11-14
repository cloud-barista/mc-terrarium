# Outputs wrapped in sql_db_info object
output "sql_db_info" {
  description = "Information for connecting to the MySQL Flexible Server instance in Azure."
  value = {
    sql_db_detail = {
      # Basic Information
      instance_name        = azurerm_mysql_flexible_server.example.name     # "tofu-example-mysql-server"
      instance_resource_id = azurerm_mysql_flexible_server.example.id       # "/subscriptions/a20fed83-96bd-4480-92a9-140b8e3b7c3a/resourceGroups/tofu-example-rg/providers/Microsoft.DBforMySQL/flexibleServers/tofu-example-mysql-server"
      instance_spec        = azurerm_mysql_flexible_server.example.sku_name # "B_Standard_B1ms"
      location             = azurerm_mysql_flexible_server.example.location # "koreacentral"
      tags                 = azurerm_mysql_flexible_server.example.tags     # (if available)

      # Storage Configuration
      storage_type = "Premium_LRS"                                            # Azure MySQL Flexible Server uses Premium storage
      storage_size = azurerm_mysql_flexible_server.example.storage[0].size_gb # 20

      # Database Engine Information
      engine_name    = "mysql"                                       # Always "mysql"
      engine_version = azurerm_mysql_flexible_server.example.version # "5.7"

      # Database Connection Details
      connection_endpoint   = "${azurerm_mysql_flexible_server.example.fqdn}:3306"                # "tofu-example-mysql-server.mysql.database.azure.com:3306"
      connection_host       = azurerm_mysql_flexible_server.example.fqdn                          # "tofu-example-mysql-server.mysql.database.azure.com"
      connection_port       = 3306                                                                # Default MySQL port
      public_access_enabled = azurerm_mysql_flexible_server.example.public_network_access_enabled # true

      # Authentication
      admin_username = azurerm_mysql_flexible_server.example.administrator_login # "adminuser"
      # admin_password = azurerm_mysql_flexible_server.example.administrator_login_password # "adminuser"

      provider_specific_detail = {
        provider            = "azure"
        resource_identifier = azurerm_mysql_flexible_server.example.id

        resource_group_name = azurerm_mysql_flexible_server.example.resource_group_name # "tofu-example-rg"
        zone                = azurerm_mysql_flexible_server.example.zone                # "2"
        database_name       = azurerm_mysql_flexible_database.example.name              # "tofu-example-db"
        charset             = azurerm_mysql_flexible_database.example.charset           # "utf8"
        collation           = azurerm_mysql_flexible_database.example.collation         # "utf8_general_ci"

        storage_autogrow_enabled = azurerm_mysql_flexible_server.example.storage[0].auto_grow_enabled  # true
        io_scaling_enabled       = azurerm_mysql_flexible_server.example.storage[0].io_scaling_enabled # false

        backup_retention_days        = azurerm_mysql_flexible_server.example.backup_retention_days        # 7
        geo_redundant_backup_enabled = azurerm_mysql_flexible_server.example.geo_redundant_backup_enabled # false

        replica_capacity = azurerm_mysql_flexible_server.example.replica_capacity # 10
        replication_role = azurerm_mysql_flexible_server.example.replication_role # "None"
      }
    }
  }
}

# output "azurerm_mysql_flexible_server_all" {
#   description = "All attributes of the Azure Database for MySQL instance."
#   value       = azurerm_mysql_flexible_server.example
#   sensitive   = true
# }

# output "azurerm_mysql_flexible_database_all" {
#   description = "All attributes of the Azure Database for MySQL database."
#   value       = azurerm_mysql_flexible_database.example
#   sensitive   = true
# }
