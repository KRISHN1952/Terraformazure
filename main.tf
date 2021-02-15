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
  subscription_id = "<subsciption ID>"
  client_id = "<APP Id>"
  client_secret = "<security principal password>"
  tenant_id = "<tenant Id>"
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
    address_prefixes     = ["10.0.0.0/24"]
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

#Azure Bastion subnet
resource "azurerm_subnet" "demobastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.newvnet.name
  address_prefixes     = ["10.0.0.0/27"]
}
resource "azurerm_public_ip" "pip" {
  name                = "pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "demobastion" {
  name                = "examplebastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.demobastion.id
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

#Nat gateway
resource "azurerm_nat_gateway" "demonat" {
  name                    = "nat-Gateway"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  }
#Nat gateway association to subnet
resource "azurerm_subnet_nat_gateway_association" "demonat" {
  subnet_id      = azurerm_subnet.newsubnet.id
  nat_gateway_id = azurerm_nat_gateway.demonat.id
}
