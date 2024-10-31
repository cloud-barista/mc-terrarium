output "CosmosDbInfo" {
  description = "Information needed to connect and manage the Azure Cosmos DB account."
  value = {
    account_name      = azurerm_cosmosdb_account.example.name
    endpoint          = azurerm_cosmosdb_account.example.endpoint
    consistency_level = azurerm_cosmosdb_account.example.consistency_policy.0.consistency_level
    database_name     = azurerm_cosmosdb_sql_database.example.name
    # primary_key       = azurerm_cosmosdb_account.example.primary_key
    # secondary_key     = azurerm_cosmosdb_account.example.secondary_key
  }
}
