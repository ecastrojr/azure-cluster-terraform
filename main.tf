provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_network_security_group" "master_nsg" {
  name                = "${var.prefix}-master-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-all-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_storage_account" "sa" {
  name                     = "${var.prefix}storacc"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "development"
  }
}

resource "azurerm_storage_share" "ss" {
  name                 = "${var.prefix}-share"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 160
}

resource "azurerm_public_ip" "master_ip" {
  name                = "${var.prefix}-masterPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "master_nic" {
  name                = "${var.prefix}-master-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.master_ip.id
  }
}

resource "azurerm_public_ip" "worker_ip" {
  count               = 2
  name                = "${var.prefix}-workerPublicIP-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "worker_nic" {
  count               = 2
  name                = "${var.prefix}-worker-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker_ip[count.index].id
  }
}

# Managed Disk
resource "azurerm_managed_disk" "shared_disk" {
  name                 = "${var.prefix}-shared-disk"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1024
}

# Master VM
resource "azurerm_virtual_machine" "master_vm" {
  name                  = "${var.prefix}-master-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  vm_size               = "Standard_F2"
  network_interface_ids = [azurerm_network_interface.master_nic.id]

  storage_os_disk {
    name          = "${var.prefix}-osdisk1"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.prefix}-master"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub") # Caminho para sua chave pública SSH local
    }
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL get.docker.com | sh",
      "ufw allow 80,443,3000,996,7946,4789,2377/tcp; ufw allow 7946,4789,2377/udp;",
      "docker run -p 80:80 -p 443:443 -p 3000:3000 -e ACCEPTED_TERMS=true -v /var/run/docker.sock:/var/run/docker.sock -v /captain:/captain caprover/caprover",
    ]

    connection {
      type        = "ssh"
      host        = azurerm_public_ip.master_ip.ip_address
      user        = var.admin_username
      # password    = var.admin_password # Remova esta linha
      agent       = false
      timeout     = "10m"
    }
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "master_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.shared_disk.id
  virtual_machine_id = azurerm_virtual_machine.master_vm.id
  lun                = 0
  caching            = "ReadWrite"
}

# Worker VMs
resource "azurerm_virtual_machine" "worker_vm" {
  count                 = 2
  name                  = "${var.prefix}-worker-vm-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  vm_size               = "Standard_F2"
  network_interface_ids = [azurerm_network_interface.worker_nic[count.index].id]

  storage_os_disk {
    name          = "${var.prefix}-osdisk-worker-${count.index}"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.prefix}-worker-${count.index}"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub") # Caminho para sua chave pública SSH local
    }
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL get.docker.com | sh",
      "ufw allow 80,443,3000,996,7946,4789,2377/tcp; ufw allow 7946,4789,2377/udp;",
    ]

    connection {
      type        = "ssh"
      host        = azurerm_public_ip.worker_ip[count.index].ip_address
      user        = var.admin_username
      # password    = var.admin_password
      agent       = false
      timeout     = "10m"
    }
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "worker_disk_attachment" {
  count               = 2
  managed_disk_id     = azurerm_managed_disk.shared_disk.id
  virtual_machine_id  = azurerm_virtual_machine.worker_vm[count.index].id
  lun                 = 0
  caching             = "ReadWrite"
}

resource "azurerm_network_interface_security_group_association" "master_nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.master_nic.id
  network_security_group_id = azurerm_network_security_group.master_nsg.id
}
