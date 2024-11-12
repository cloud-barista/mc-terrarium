output "sql_db_info" {
  description = "Information needed to connect and manage the Azure Database for MySQL instance."
  value = {
    terrarium = {
      id = var.terrarium_id
    }
    azure = {
      instance_identifier = azurerm_mysql_flexible_server.instance.name
      connection_info     = azurerm_mysql_flexible_server.instance.fqdn
      port                = 3306 # var.db_engine_port
      admin_username      = azurerm_mysql_flexible_server.instance.administrator_login
      database_name       = azurerm_mysql_flexible_database.engine.name
      region              = azurerm_mysql_flexible_server.instance.location
      resource_group      = azurerm_mysql_flexible_server.instance.resource_group_name
    }
  }
}
