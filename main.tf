# login AZ
provider "azurerm" {
	features {}
    subscription_id = "dae8166f-6682-4dea-85d1-178bb6576603"
    tenant_id       = "c7e9fa8d-0b86-4099-9b6f-001f13bcacdb"
}
# create resource group AZ
resource "azurerm_resource_group" "windowsRG" {
    name     = "${var.name}"
    location = "${var.location}"
    }

resource "azurerm_virtual_network" "main" {
  name                = "Vertual-network"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.windowsRG.location
  resource_group_name = azurerm_resource_group.windowsRG.name
}
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.windowsRG.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.2.0/24"]
}
resource "azurerm_public_ip" "ip_public" {
  name                = "ippublic"
  resource_group_name = azurerm_resource_group.windowsRG.name
  location            = azurerm_resource_group.windowsRG.location
  allocation_method   = "Static"
}
resource "azurerm_network_security_group" "windowsNSG" {
  name                = "windowsNSG"
  location            = azurerm_resource_group.windowsRG.location
  resource_group_name = azurerm_resource_group.windowsRG.name

  security_rule {
    name                       = "ssh"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
   security_rule {
    name                       = "rdp"
    priority                   = 301
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_interface" "main" {
  name                = "NIC"
  location            = azurerm_resource_group.windowsRG.location
  resource_group_name = azurerm_resource_group.windowsRG.name

  ip_configuration {
    name                          = "IPCONFIG"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip_public.id
  }
}
resource "azurerm_network_interface_security_group_association" "NSGA" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.windowsNSG.id
}

# create VM
resource "azurerm_windows_virtual_machine" "VM" {
  name                = "${var.VM}"
  resource_group_name = azurerm_resource_group.windowsRG.name
  location            = azurerm_resource_group.windowsRG.location
  network_interface_ids = [azurerm_network_interface.main.id]
  size               = "Standard_F2"
  admin_username      = "${var.username}"
  admin_password      = "${var.pass}"
 
#  admin_ssh_key {
#     username   = "${var.username}"
#     public_key = file("~/.ssh/id_rsa.pub")
#   }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
 
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  # data "azurerm_public_ip" "ip_public" {
  # name                = azurerm_public_ip.ip_public.name
  # resource_group_name = azurerm_virtual_machine.ip_public.windowsRG
  # }
  # output "public_ip_address" {
  # value = data.azurerm_public_ip.ip_public.ip_address
  # }
}
