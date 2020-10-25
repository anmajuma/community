
resource "azurerm_resource_group" "rg" {
  name     = "${var.environment_name}-rg"
  location = var.resource_location
  tags = var.tags
}

resource "random_password" "sql_admin_pwd" {
  length = 50
}

resource "azurerm_sql_server" "sql" {
  name                         = "${var.environment_name}-sql"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sql_admin_pwd.result
  tags = var.tags
}

resource "azurerm_sql_firewall_rule" "azure_fw_rule" {
  name                = "AzureServices"
  resource_group_name = azurerm_sql_server.sql.resource_group_name
  server_name         = azurerm_sql_server.sql.name
  start_ip_address    = "0.0.0.0"  # = 'Allow access to Azure services'
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_sql_database" "db" {
  name                = "ExampleDb"
  resource_group_name = azurerm_sql_server.sql.resource_group_name
  location            = azurerm_sql_server.sql.location
  server_name         = azurerm_sql_server.sql.name
  edition             = "Basic"
  tags                = var.tags
}

output "db_connection_string" {
  value = "Server=tcp:${azurerm_sql_server.sql.name},1433;Initial Catalog=ExampleDb;User ID=sqladmin;Password=${azurerm_sql_server.sql.administrator_login_password};"
  sensitive = true  
}

resource "azurerm_data_factory" "adf" {
  name                = "${var.environment_name}-adf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}