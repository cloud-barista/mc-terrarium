output "MySqlDbInfo" {
  description = "Information needed to connect and manage the Azure Database for MySQL instance."
  value = {
    server_name                 = azurerm_mysql_flexible_server.example.name
    fully_qualified_domain_name = azurerm_mysql_flexible_server.example.fqdn
    administrator_login         = azurerm_mysql_flexible_server.example.administrator_login
    administrator_password      = "YOUR_PASSWORD_HERE" # Note: Avoid exposing this directly; consider using a secret management tool
    database_name               = azurerm_mysql_flexible_database.example.name
    port                        = 3306
    # ssl_enforcement             = azurerm_mysql_flexible_server.example.ssl_enforcement_enabled
  }
}
