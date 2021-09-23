#VARIABLES

variable "resource_group_name"{
    type = string
}
variable "location"{
    type = string
    default = "westus"
}
variable "vnet_cidr_range"{
    type = list(string)
    default = ["10.0.0.0/16"]
}

variable "subnet_count"{
    default = 2
}

variable "vm_count"{
    default = 2
}

variable subnet_cidr{
    type = list(string)
    default = ["10.0.0.0/24","10.0.1.0/24"]
}


#PROVIDER

provider "azurerm"{
    features {}
    subscription_id = "__subscriptionid__"
    tenant_id = "__tenantid__"
    client_id = "__clientid__"
}
#DATA
data "azurerm_key_vault" "existing" {
  name                = "mykeyvault"
  resource_group_name = azurerm_resource_group.example.name
}
data "azurerm_key_vault_secret" "example" {
  name         = "vm-password"
  key_vault_id = data.azurerm_key_vault.existing.id
}

#RESOURCES

resource "azurerm_resource_group" "example"{
    name = var.resource_group_name
    location = var.location
}
resource "azurerm_network_security_group" "nsg" {
  name                = "TestSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
  }

  resource "azurerm_network_security_rule" "example" {
  name                        = "test123"
  priority                    = 100
  direction                   = "inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
 resource "azurerm_network_security_rule" "example1" {
  name                        = "test123"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}


resource "azurerm_virtual_network" "example" {
  name                = "my-vnet"
  address_space       = var.vnet_cidr_range
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  
}
resource "azurerm_subnet" "subnet" {
    count = var.subnet_count
    name                 = "subnet-${count.index}"
    resource_group_name  = azurerm_resource_group.example.name
    virtual_network_name = azurerm_virtual_network.example.name
    address_prefixes     = var.subnet_cidr
}



resource "azurerm_storage_account" "sa"{
    name = "mystorageaccount"
    resource_group_name = azurerm_resource_group.example.name
    location = var.location
    account_tier = "Standard"
    account_replication_type = "LRS"
}
resource azurerm_network_interface "app"{
    count = var.vm_count
    name = "nic-${count.index}"
    location = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name

    ip_configuration {
      name ="config"
      subnet_id = azurerm_subnet.subnet[count.index].id
      private_ip_address_allocation =  "Dynamic"
    }
}

resource "azurerm_virtual_machine" "app" {
    count = var.vm_count
    name                 = "vm-${count.index}"
    location =  azurerm_resource_group.example.location
    resource_group_name  = azurerm_resource_group.example.name
    network_interface_ids = azurerm_network_interface.app[count.index].id
    vm_size = "Standard_DS1_v2"
    
    delete_data_disks_on_termination = true
    delete_os_disk_on_termination = true

    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku="16.04-LTS"
        version="latest"  
    }
    os_profile{
        computer_name = "App-VM-${count.index}"
        admin_username = "admin"
        admin_password = data.azurerm_key_vault_secret.example.value

    }
    storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
}
output "vm_ip" {
   
        value = azurerm_virtual_machine.app.name
    }