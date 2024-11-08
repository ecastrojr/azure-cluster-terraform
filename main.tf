# Define o provedor AzureRM para gerenciar recursos no Azure
provider "azurerm" {
  features {}
}

# Grupo de Recursos onde todos os recursos do cluster serão implantados
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-cluster"
  location = var.location
}

# Grupo de Segurança de Rede (NSG) para o Master, permite todo tráfego de entrada (para fins de teste)
resource "azurerm_network_security_group" "master_nsg" {
  name                = "${var.prefix}-master-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Regra de segurança que permite todo tráfego de entrada
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

# Grupo de Segurança de Rede (NSG) para os Workers, restringe SSH ao IP do usuário
resource "azurerm_network_security_group" "worker_nsg" {
  name                = "${var.prefix}-worker-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Regra de segurança que permite SSH apenas do IP do usuário
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

# Rede Virtual (VNet) e Subnet para as VMs
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

# Conta de Armazenamento para armazenamento compartilhado no cluster
resource "azurerm_storage_account" "sa" {
  name                     = "${var.prefix}storacc"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "ss" {
  name                 = "${var.prefix}-share"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 160
}

# IPs Públicos para as VMs Master e Workers
resource "azurerm_public_ip" "master_ip" {
  name                = "${var.prefix}-masterPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "worker_ip" {
  count               = 2
  name                = "${var.prefix}-workerPublicIP-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Interface de Rede para a VM Master
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

# Interfaces de Rede para as VMs Workers
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

# Disco Gerenciado para armazenamento compartilhado
resource "azurerm_managed_disk" "shared_disk" {
  name                 = "${var.prefix}-shared-disk"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.shared_disk_size

  lifecycle {
    prevent_destroy = false  # Permite destruir o disco ao rodar terraform destroy
  }
}

# Configuração da VM Master
resource "azurerm_virtual_machine" "master_vm" {
  name                  = "${var.prefix}-master-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  vm_size               = var.master_vm_size
  network_interface_ids = [azurerm_network_interface.master_nic.id]

  storage_os_disk {
    name          = "${var.prefix}-osdisk1"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  lifecycle {
    prevent_destroy = false  # Permite destruir a VM e o disco ao rodar terraform destroy
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
      key_data = file(var.ssh_public_key_path)
    }
  }

  storage_image_reference {
    publisher = var.ubuntu_image.publisher
    offer     = var.ubuntu_image.offer
    sku       = var.ubuntu_image.sku
    version   = var.ubuntu_image.version
  }

provisioner "remote-exec" {
    inline = [
      "curl -fsSL get.docker.com | sh",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo mkdir -p /opt/docker",
      "sudo mount -t cifs //${azurerm_storage_account.sa.name}.file.core.windows.net/${azurerm_storage_share.ss.name} /mnt/disks -o vers=3.0,username=${azurerm_storage_account.sa.name},password=${azurerm_storage_account.sa.primary_access_key},dir_mode=0777,file_mode=0777",
    ]

    connection {
      type        = "ssh"
      host        = azurerm_public_ip.master_ip.ip_address
      user        = var.admin_username
      private_key = file(var.ssh_private_key_path)
    }
  }
}

# Configuração das VMs Workers
resource "azurerm_virtual_machine" "worker_vm" {
  count                 = 2
  name                  = "${var.prefix}-worker-vm-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  vm_size               = var.worker_vm_size
  network_interface_ids = [azurerm_network_interface.worker_nic[count.index].id]

  storage_os_disk {
    name          = "${var.prefix}-osdisk-worker-${count.index}"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  lifecycle {
    prevent_destroy = false  # Permite destruir a VM e o disco ao rodar terraform destroy
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
      key_data = file(var.ssh_public_key_path)
    }
  }

  storage_image_reference {
    publisher = var.ubuntu_image.publisher
    offer     = var.ubuntu_image.offer
    sku       = var.ubuntu_image.sku
    version   = var.ubuntu_image.version
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL get.docker.com | sh",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo mkdir -p /opt/docker",
      "sudo mount -t cifs //${azurerm_storage_account.sa.name}.file.core.windows.net/${azurerm_storage_share.ss.name} /mnt/disks -o vers=3.0,username=${azurerm_storage_account.sa.name},password=${azurerm_storage_account.sa.primary_access_key},dir_mode=0777,file_mode=0777",
    ]

    connection {
      type        = "ssh"
      host        = azurerm_public_ip.worker_ip[count.index].ip_address
      user        = var.admin_username
      private_key = file(var.ssh_private_key_path)
    }
  }


}

# Associação de NSG para a NIC do Master
resource "azurerm_network_interface_security_group_association" "master_nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.master_nic.id
  network_security_group_id = azurerm_network_security_group.master_nsg.id
}

# Associação de NSG para as NICs dos Workers
resource "azurerm_network_interface_security_group_association" "worker_nic_nsg_association" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.worker_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.worker_nsg.id
}