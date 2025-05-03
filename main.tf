provider "azurerm" {
    features {}
    subscription_id = "f8385bb6-b2a7-45e4-9372-3cf777dc941a"
}

# Create a resource group
resource "azurerm_resource_group" "Testing-Terraform" {
    name     = "testing-terraform"
    location = "East US"
}
# Create a virtual network and subnet
resource "azurerm_virtual_network" "TT-VNet" {
    name                = "testing-terraform-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.Testing-Terraform.location
    resource_group_name = azurerm_resource_group.Testing-Terraform.name
}

resource "azurerm_subnet" "TT-SNet" {
    name                 = "testing-terraform-subnet"
    resource_group_name  = azurerm_resource_group.Testing-Terraform.name
    virtual_network_name = azurerm_virtual_network.TT-VNet.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "testing-terraform-nic" {
    name                = "testing-terraform-nic"
    location            = azurerm_resource_group.Testing-Terraform.location
    resource_group_name = azurerm_resource_group.Testing-Terraform.name

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.TT-SNet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id         = azurerm_public_ip.testing_terraform_pip.id
    }
}

resource "azurerm_public_ip" "testing_terraform_pip" {
    name                = "testing-terraform-pip"
    location            = azurerm_resource_group.Testing-Terraform.location
    resource_group_name = azurerm_resource_group.Testing-Terraform.name
    allocation_method   = "Static"
    sku                = "Standard"
}

# Create a network security group and rules
resource "azurerm_network_security_group" "testing-terraform-nsg" {
    name                = "testing-terraform-nsg"
    location            = azurerm_resource_group.Testing-Terraform.location
    resource_group_name = azurerm_resource_group.Testing-Terraform.name

    security_rule {
        name                       = "SSH"
        priority                   = 300
        direction                  = "Inbound"
        access                    = "Allow"
        protocol                  = "Tcp"
        source_port_range         = "*"
        destination_port_range    = 22
        source_address_prefix     = var.source_address_prefix
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTPS"
        priority                   = 301
        direction                  = "Inbound"
        access                    = "Allow"
        protocol                  = "Tcp"
        source_port_range         = "*"
        destination_port_range    = 443
        source_address_prefix     = "*"
        destination_address_prefix = "*"
    }

        security_rule {
        name                       = "HTTP"
        priority                   = 302
        direction                  = "Inbound"
        access                    = "Allow"
        protocol                  = "Tcp"
        source_port_range         = "*"
        destination_port_range    = 80
        source_address_prefix     = "*"
        destination_address_prefix = "*"
    }
}

# Associate the network interface with the network security group
resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
    network_interface_id      = azurerm_network_interface.testing-terraform-nic.id
    network_security_group_id = azurerm_network_security_group.testing-terraform-nsg.id
}

resource "azurerm_linux_virtual_machine" "n8n-vm" {
    name                = "n8n-vm"
    resource_group_name = azurerm_resource_group.Testing-Terraform.name
    location            = azurerm_resource_group.Testing-Terraform.location
    size                = "Standard_B1s"
    admin_username      = var.admin_username
    admin_password      = var.admin_password
    disable_password_authentication = "false"

    network_interface_ids = [
        azurerm_network_interface.testing-terraform-nic.id,
    ]

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "ubuntu-24_04-lts"
        sku       = "server"
        version   = "latest"
    }
}