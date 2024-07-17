resource "azurerm_resource_group" "rg" {
  name     = "casopractico2-lgc2--rg"
  location = "West Europe"
}

resource "azurerm_container_registry" "acr" {
  name                = "casopractico2lgc2acr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_virtual_network" "vnet" {
  name                = "casopractico2-lgc2--vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "publicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "casopractico2-lgc2--vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_B1ms""Standard_D2s_v3"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "lgcdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "casopractico2-lgc2-vm"
    admin_username = "leo_gomez"
    admin_password = "Rock4YouNot4Me"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

#resource "azurerm_kubernetes_cluster" "aks" {
#  name                = "casopractico2-lgc2--aks"
#  location            = azurerm_resource_group.rg.location
#  resource_group_name = azurerm_resource_group.rg.name
#  dns_prefix          = "casopractico2-lgc2--aks"
#
#  default_node_pool {
#    name       = "default"
#    node_count = 1
#    vm_size    = "Standard_D2s_v3"
#  }
#
#  identity {
#    type = "SystemAssigned"
#  }
#
#  network_profile {
#    network_plugin    = "azure"
#    load_balancer_sku = "standard"
#  }
#
#}

