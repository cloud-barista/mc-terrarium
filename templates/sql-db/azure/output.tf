output "sql_db_info" {
  description = "Information needed to connect and manage the Azure Database for MySQL instance."
  value = {
    location                    = azurerm_mysql_flexible_server.instance.location
    resource_group_name         = azurerm_mysql_flexible_server.instance.resource_group_name
    server_name                 = azurerm_mysql_flexible_server.instance.name
    fully_qualified_domain_name = azurerm_mysql_flexible_server.instance.fqdn
    administrator_login         = azurerm_mysql_flexible_server.instance.administrator_login
    # administrator_password      = "YOUR_PASSWORD_HERE" # Note: Avoid exposing this directly; consider using a secret management tool
    database_name = azurerm_mysql_flexible_database.engine.name
    port          = 3306
    # ssl_enforcement             = azurerm_mysql_flexible_server.example.ssl_enforcement_enabled
  }
}
