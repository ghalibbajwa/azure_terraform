provider "azurerm" {
  features {}
}

variable "regions" {
  type    = list(string)
  default = ["australiacentral","australiacentral2","australiaeast","australiasoutheast","brazilsouth","brazilsoutheast","brazilus","canadacentral","canadaeast","centralindia","centralus","centraluseuap","eastasia","eastus","eastus2","eastus2euap","francecentral","francesouth","germanynorth","germanywestcentral","israelcentral","italynorth","japaneast","japanwest","jioindiacentral","jioindiawest","koreacentral","koreasouth","malaysiasouth","northcentralus","northeurope","norwayeast","norwaywest","polandcentral","qatarcentral","southafricanorth","southafricawest","southcentralus","southeastasia","southindia","swedencentral","swedensouth","switzerlandnorth","switzerlandwest","uaecentral","uaenorth","uksouth","ukwest","westcentralus","westeurope","westindia","westus","westus2","westus3","austriaeast","chilecentral","eastusslv","israelnorthwest","malaysiawest","mexicocentral","newzealandnorth","southeastasiafoundational","spaincentral","taiwannorth","taiwannorthwest"
]  # Add more regions as needed
}



resource "azurerm_resource_group" "slogr" {
  name     = "slogr-resources"
  location = "eastus"
}



resource "azurerm_virtual_network" "slogr" {
  name                = "slogr-network"
  location            = azurerm_resource_group.slogr.location
  resource_group_name = azurerm_resource_group.slogr.name
  address_space       = ["10.0.0.0/16"]
}


resource "azurerm_network_security_group" "slogr" {
  name                = "slogr-nsg"
  location            = azurerm_resource_group.slogr.location
  resource_group_name = azurerm_resource_group.slogr.name
}

resource "azurerm_network_security_rule" "allow_all_tcp" {
  name                        = "allow-all-tcp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.slogr.name
  network_security_group_name  = azurerm_network_security_group.slogr.name
}

resource "azurerm_network_security_rule" "allow_all_udp_60000" {
  name                        = "allow-all-udp-60000"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "60000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.slogr.name
  network_security_group_name  = azurerm_network_security_group.slogr.name
}

resource "azurerm_network_security_rule" "allow_all_tcp_outbound" {
  name                        = "allow-all-tcp-outbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.slogr.name
  network_security_group_name  = azurerm_network_security_group.slogr.name
}

resource "azurerm_network_security_rule" "allow_all_udp_60000_outbound" {
  name                        = "allow-all-udp-60000-outbound"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "60000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.slogr.name
  network_security_group_name  = azurerm_network_security_group.slogr.name
}




resource "azurerm_network_interface_security_group_association" "slogr" {
  network_interface_id      = azurerm_network_interface.slogr.id
  network_security_group_id = azurerm_network_security_group.slogr.id
}


resource "azurerm_public_ip" "slogr" {
  name                = "slogr-publicip"
  location            = azurerm_resource_group.slogr.location
  resource_group_name = azurerm_resource_group.slogr.name
  allocation_method   = "Dynamic"  # or "Static" if you want a static IP
}

resource "azurerm_subnet" "slogr" {
  name                 = "slogr-subnet"
  resource_group_name  = azurerm_resource_group.slogr.name
  virtual_network_name = azurerm_virtual_network.slogr.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "slogr" {
  name                = "slogr-nic"
  location            = azurerm_resource_group.slogr.location
  resource_group_name = azurerm_resource_group.slogr.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.slogr.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.slogr.id
  }
}

resource "azurerm_linux_virtual_machine" "slogr" {
  count                = length(var.regions)
  name                 = "vm-${var.regions[count.index]}"
  location             = var.regions[count.index]
  resource_group_name  = azurerm_resource_group.slogr.name
  network_interface_ids = [azurerm_network_interface.slogr.id]
  size                 = "Standard_B1ls"

  admin_username = "slogr"
  admin_password = "Password1234!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

 source_image_reference {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2" # or "18.04-LTS" or another supported version
  version   = "latest"
}

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL get.docker.com -o get-docker.sh",  
      "sudo sh get-docker.sh",       
      "git clone https://github.com/slogr/slogr-twamp.git",
      "cd slogr-twamp/agent/",
      "sudo docker compose up -d"
    ]

     connection {
      type        = "ssh"
      user        = "ad" # Replace with your VM's admin username
      password    = "pwd"  # Replace with your VM's admin password
      host        = self.public_ip_address
    }

    when = "create"
  }
}
