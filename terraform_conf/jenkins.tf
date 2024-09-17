# Get current client configuration
data "azurerm_client_config" "current" {}


# Create Azure Key Vault
resource "azurerm_key_vault" "jenkins" {
  name                = "twobcloud123"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "standard"

  tenant_id = data.azurerm_client_config.current.tenant_id
}

# Create Azure Container Registry
resource "azurerm_container_registry" "jenkins" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = true
}

# Create Virtual Network and Subnet for the VM
resource "azurerm_virtual_network" "jenkins" {
  name                = "jenkins-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "jenkins" {
  name                 = "jenkins-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.jenkins.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Network Interface for the VM
resource "azurerm_network_interface" "jenkins" {
  name                = "jenkins-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jenkins.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins.id
  }

}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.jenkins.id
  network_security_group_id = azurerm_network_security_group.jenkins_nsg.id
}


# Create Public IP for the VM
resource "azurerm_public_ip" "jenkins" {
  name                = "jenkins-pip1"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "jenkins_nsg" {
  name                = "jenkins-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowJenkins"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


# Create Virtual Machine for Jenkins
resource "azurerm_linux_virtual_machine" "example" {
  name                  = "jenkinsVM"
  location              = var.location
  resource_group_name   = var.resource_group_name
  admin_username        = var.vm_admin_username
  network_interface_ids = [azurerm_network_interface.jenkins.id]
  size                  = "Standard_DS1_v2"
  user_data             = base64encode(file("userdata.tftpl"))

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}


