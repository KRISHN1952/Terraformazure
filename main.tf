terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.47.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "9a85f5f2-efaf-40c4-8cc6-35db4b8db382"
  client_id = "99638a67-d587-4afa-b3fa-fb5ea1920eb6"
  client_secret = "0Xtd5Cu-IuWLTOg6.kpfVok6dPR_BAZzt4"
  tenant_id = "576e9fe2-f0f8-4516-a602-c761e0251236"
}

#resource group
resource "azurerm_resource_group" "rg" {
  name = "rg"
  location = "Central India"
}

# VNet
resource "azurerm_virtual_network" "newvnet" {
  name                = "vnetdemo"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/22"]
 }
 
 #subnet
resource "azurerm_subnet" "newsubnet" {
    name                 = "Subnetdemo"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.newvnet.name
    address_prefixes     = ["10.0.1.0/24"]
}

#NICcard
resource "azurerm_network_interface" "server_nic" {
  name                = "webserver-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "weberver-ip"
    subnet_id                     = azurerm_subnet.newsubnet.id
    private_ip_address_allocation = "dynamic"
  }
}

#NSG
resource "azurerm_network_security_group" "server_nsg" {
  name                = "webserver-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name                        = "RDP Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.server_nsg.name
}

resource "azurerm_network_interface_security_group_association" "server_nsg_association" {
  network_security_group_id = azurerm_network_security_group.server_nsg.id
  network_interface_id      = azurerm_network_interface.server_nic.id
}

resource "azurerm_windows_virtual_machine" "server" {
  name                  = "demo_server"
  location              = "westus2"
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.server_nic.id]
  size                  = "Standard_B1s"
  admin_username        = "webserver"
  admin_password        = "Passw0rd1234"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

}
