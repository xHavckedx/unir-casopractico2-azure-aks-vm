resource "azurerm_resource_group" "rg" {
  name     = "casopractico2-lgc2--rg"
  location = "North Europe"
}

resource "azurerm_container_registry" "acr" {
  name                = "casopractico2lgc2acr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true

  depends_on = [azurerm_resource_group.rg]
}


data "azurerm_container_registry" "acr_data" {
  name                = azurerm_container_registry.acr.name
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [azurerm_container_registry.acr]
}

resource "azurerm_virtual_network" "vnet" {
  name                = "casopractico2-lgc2--vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "publicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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
  
  # Añadir una regla para el puerto 443
  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-lgc"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }

  depends_on = [
    azurerm_subnet.subnet,
    azurerm_public_ip.public_ip,
    azurerm_network_security_group.nsg
  ]
}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [azurerm_network_interface.nic]
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "casopractico2-lgc2--vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_B1ms" #"Standard_D2s_v3"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
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
    admin_password = "some-shit1234"
    custom_data    = <<-EOF
      #cloud-config
      write_files:
        - path: /etc/environment
          permissions: '0644'
          content: |
            ACR_ADMIN_USERNAME=${data.azurerm_container_registry.acr_data.admin_username}
            ACR_ADMIN_PASSWORD=${data.azurerm_container_registry.acr_data.admin_password}
    EOF

  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/leo_gomez/.ssh/authorized_keys"
      key_data = file("./.ssh/authorized_keys")
    }
  }

  depends_on = [
    azurerm_network_interface.nic,
    azurerm_network_interface_security_group_association.nsg_association
  ]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "casopractico2-lgc2--aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "casopractico2-lgc2--aks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  depends_on = [
    azurerm_virtual_machine.vm
  ]
}
