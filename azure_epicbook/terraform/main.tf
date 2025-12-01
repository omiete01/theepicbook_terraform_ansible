terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "048a1739-6bf8-4f17-acf5-263808ba8d22"
}

# Azure Resource Group
resource "azurerm_resource_group" "epicbook-rg" {
  name     = "${var.vpc_name}-rg"
  location = var.location

  tags = {
    Name = "${var.vpc_name}-rg"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "epicbook-vnet" {
  name                = "${var.vpc_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.epicbook-rg.location
  resource_group_name = azurerm_resource_group.epicbook-rg.name

  tags = {
    Name = "${var.vpc_name}-vnet"
  }
}

# Public Subnet for the VM
resource "azurerm_subnet" "epicbook-pub-subnet" {
  name                 = "${var.vpc_name}-pub-subnet"
  resource_group_name  = azurerm_resource_group.epicbook-rg.name
  virtual_network_name = azurerm_virtual_network.epicbook-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Private Subnet 1 for the Database
resource "azurerm_subnet" "epicbook-priv-subnet1" {
  name                 = "${var.vpc_name}-priv-subnet1"
  resource_group_name  = azurerm_resource_group.epicbook-rg.name
  virtual_network_name = azurerm_virtual_network.epicbook-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "epicbook_fs"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Private Subnet 2 for the Database
resource "azurerm_subnet" "epicbook-priv-subnet2" {
  name                 = "${var.vpc_name}-priv-subnet2"
  resource_group_name  = azurerm_resource_group.epicbook-rg.name
  virtual_network_name = azurerm_virtual_network.epicbook-vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Public IP for the VM
resource "azurerm_public_ip" "epicbook-pip" {
  name                = "epicbook-vm-pip"
  location            = azurerm_resource_group.epicbook-rg.location
  resource_group_name = azurerm_resource_group.epicbook-rg.name
  allocation_method   = "Static"

  tags = {
    Name = "epicbook-vm-pip"
  }
}

# Network Security Group for VM
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vm_name}-nsg"
  location            = azurerm_resource_group.epicbook-rg.location
  resource_group_name = azurerm_resource_group.epicbook-rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Outbound"
    priority                   = 1003
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "vm-nsg"
  }
}

# Network Security Group for Database
resource "azurerm_network_security_group" "db_nsg" {
  name                = "mysql-to-vm-nsg"
  location            = azurerm_resource_group.epicbook-rg.location
  resource_group_name = azurerm_resource_group.epicbook-rg.name

  security_rule {
    name                       = "MySQL"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = azurerm_subnet.epicbook-priv-subnet1.address_prefixes[0]
    destination_address_prefix = "*"
  }

  tags = {
    Name = "db-nsg"
  }
}

# Network Interface for VM
resource "azurerm_network_interface" "epicbook_nic" {
  name                = "epicbook-vm-nic"
  location            = azurerm_resource_group.epicbook-rg.location
  resource_group_name = azurerm_resource_group.epicbook-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.epicbook-pub-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.epicbook-pip.id
  }

  tags = {
    Name = "epicbook-vm-nic"
  }
}

# Associate Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "vm_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.epicbook_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "vm_subnet_assoc" {
  subnet_id                 = azurerm_subnet.epicbook-pub-subnet.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "db_subnet_assoc" {
  subnet_id                 = azurerm_subnet.epicbook-priv-subnet1.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "epicbook_vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.epicbook-rg.name
  location            = azurerm_resource_group.epicbook-rg.location
  size                = var.vm_size
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.epicbook_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.ssh_public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Name = var.vm_name
  }
}

# MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "mysql_server" {
  name                   = var.mysql_name
  resource_group_name    = azurerm_resource_group.epicbook-rg.name
  location               = azurerm_resource_group.epicbook-rg.location
  administrator_login    = var.mysql_username
  administrator_password = var.mysql_password
  delegated_subnet_id = azurerm_subnet.epicbook-priv-subnet1.id

  sku_name = var.mysql_sku_name

  tags = {
    Name = var.mysql_name
  }
}
