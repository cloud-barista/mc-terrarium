# Outputs wrapped in sql_db_info object
output "sql_db_info" {
  description = "Information of the MySQL Flexible Server instance in Azure."
  value = {
    terrarium = {
      id = var.terrarium_id
    }
    sql_db_detail = {
      # Basic Information
      instance_name        = azurerm_mysql_flexible_server.instance.name     # "tofu-example-mysql-server"
      instance_resource_id = azurerm_mysql_flexible_server.instance.id       # "/subscriptions/a20fed83-96bd-4480-92a9-140b8e3b7c3a/resourceGroups/tofu-example-rg/providers/Microsoft.DBforMySQL/flexibleServers/tofu-example-mysql-server"
      instance_spec        = azurerm_mysql_flexible_server.instance.sku_name # "B_Standard_B1ms"
      location             = azurerm_mysql_flexible_server.instance.location # "koreacentral"
      tags                 = azurerm_mysql_flexible_server.instance.tags     # (if available)

      # Storage Configuration
      storage_type = "Premium_LRS"                                             # Azure MySQL Flexible Server uses Premium storage
      storage_size = azurerm_mysql_flexible_server.instance.storage[0].size_gb # 20

      # Database Engine Information
      engine_name    = "mysql"                                        # Always "mysql"
      engine_version = azurerm_mysql_flexible_server.instance.version # "5.7"

      # Database Connection Details
      connection_endpoint   = "${azurerm_mysql_flexible_server.instance.fqdn}:3306"                # "tofu-example-mysql-server.mysql.database.azure.com:3306"
      connection_host       = azurerm_mysql_flexible_server.instance.fqdn                          # "tofu-example-mysql-server.mysql.database.azure.com"
      connection_port       = 3306                                                                 # Default MySQL port
      public_access_enabled = azurerm_mysql_flexible_server.instance.public_network_access_enabled # true

      # Authentication
      admin_username = azurerm_mysql_flexible_server.instance.administrator_login # "adminuser"
      # admin_password = azurerm_mysql_flexible_server.example.administrator_login_password # "adminuser"

      provider_specific_detail = {
        provider            = "azure"
        region              = azurerm_mysql_flexible_server.instance.location
        zone                = azurerm_mysql_flexible_server.instance.zone                # "2"
        resource_group_name = azurerm_mysql_flexible_server.instance.resource_group_name # "tofu-example-rg"

        resource_identifier = azurerm_mysql_flexible_server.instance.id

        database_name = azurerm_mysql_flexible_database.engine.name      # "tofu-example-db"
        charset       = azurerm_mysql_flexible_database.engine.charset   # "utf8"
        collation     = azurerm_mysql_flexible_database.engine.collation # "utf8_general_ci"

        storage_autogrow_enabled = azurerm_mysql_flexible_server.instance.storage[0].auto_grow_enabled  # true
        io_scaling_enabled       = azurerm_mysql_flexible_server.instance.storage[0].io_scaling_enabled # false

        backup_retention_days        = azurerm_mysql_flexible_server.instance.backup_retention_days        # 7
        geo_redundant_backup_enabled = azurerm_mysql_flexible_server.instance.geo_redundant_backup_enabled # false

        replica_capacity = azurerm_mysql_flexible_server.instance.replica_capacity # 10
        replication_role = azurerm_mysql_flexible_server.instance.replication_role # "None"
      }
    }
  }
}
