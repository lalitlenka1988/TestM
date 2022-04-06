provider "azurerm" {
  version = "=2.5.0"
  features {}
}
variable "subnet_prefix" {
  type = "list"
  default = [
    {
      ip      = "10.0.1.0/24"
      name     = "subnet-1"
    },
    {
      ip      = "10.0.2.0/24"
      name     = "subnet-2"
    }
   ]
}
variable "Vm_prefix" {
  type = "list"
  default = [
    {
      name     = "Vm-1"
    },
    {
      
      name     = "Vm-2"
    }
   ]
}

resource "azurerm_resource_group" "rg" {
  name     = "TerraformTesting"
  location = "eastus"
}

resource "azurerm_availability_set" "DemoAset" {
  name                = "test-aset"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurestack_network_security_group" "test" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurestack_resource_group.test.location
  resource_group_name = azurestack_resource_group.test.name
  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80,443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_virtual_network" "vnet" {
  name                = "vNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
    name = "${lookup(element(var.subnet_prefix, count.index), "name")}"
    count = "${length(var.subnet_prefix)}"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefix = "${lookup(element(var.subnet_prefix, count.index), "ip")}"
	security_group = azurestack_network_security_group.test.id
}

resource "azurerm_network_interface" "test" {
  name                = "test-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "test" {
  
  name="${lookup(element(var.Vm_prefix, count.index), "name")}"
  count = "${length(var.Vm_prefix)}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  availability_set_id = azurerm_availability_set.DemoAset.id
  network_interface_ids = [
    azurerm_network_interface.test.id,
  ]

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
}
resource "azurerm_storage_account" "example" {
  name                     = "test_storageaccountname"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

 }