provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=2.0.0"
  subscription_id = "a47cc0fd-c08c-44c8-8011-84fc1a7fdd65"
  tenant_id       = "72f988bf-86f1-41af-91ab-2d7cd011db47"
  features {}
}

resource "azurerm_resource_group" "network" {
  name     = "rg-ne-core-network"
  location = "North Europe"
}

resource "azurerm_virtual_network" "network" {
  name                = "vn-product"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = ["10.0.0.0/8"]

  tags = {
    environment = "Production"
  }
}

resource "azurerm_subnet" "snApplicationGateway01" {
  name           = "sn-ApplicationGateway-01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefix = "10.0.0.0/24"
}

resource "azurerm_subnet" "snManagementAKS01" {
  name           = "sn-ManagementAKS-01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefix = "10.0.1.0/24"
}

resource "azurerm_subnet" "snManagement01" {
  name           = "sn-Management-01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefix = "10.0.2.0/24"
}

resource "azurerm_subnet" "snServiceEndpoints01" {
  name           = "sn-ServiceEndpoints-01"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.network.name

  address_prefix = "10.0.3.0/24"
  service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
}

resource "azurerm_subnet" "snPrivateLink01" {
  name           = "sn-PrivateLink-01"
  address_prefix = "10.0.4.0/24"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.network.name
     
  enforce_private_link_endpoint_network_policies = true  
}

resource "azurerm_network_security_group" "nsgManagement" {
  name                = "nsg-Management"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet_network_security_group_association" "ManagementNSG" {
  subnet_id                 = azurerm_subnet.snManagement01.id
  network_security_group_id = azurerm_network_security_group.nsgManagement.id
}

resource "azurerm_resource_group" "dns" {
  name     = "rg-ne-core-dns"
  location = "North Europe"
}

resource "azurerm_dns_zone" "public" {
  name                = "product1.egcomp.co.uk"
  resource_group_name = azurerm_resource_group.dns.name
}

resource "azurerm_private_dns_zone" "example-private" {
  name                = "local.product1"
  resource_group_name = azurerm_resource_group.dns.name
}

resource "azurerm_public_ip" "nat-pip" {
  name                = "nat-gateway-publicIP"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}

resource "azurerm_nat_gateway" "example" {
  name                    = "nat-Gateway"
  location                = azurerm_resource_group.network.location
  resource_group_name     = azurerm_resource_group.network.name
  public_ip_address_ids   = [azurerm_public_ip.nat-pip.id]
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
}

