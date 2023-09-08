variable "prefix" {
  description = "Prefixo para nomear recursos"
  default     = "codions"
}

variable "location" {
  description = "Localização do Azure para implantar os recursos"
  default     = "East US"
}

variable "master_vm_size" {
  description = "Tamanho da VM para os masters"
  default     = "Standard_D4s_v3"
}

variable "worker_vm_size" {
  description = "Tamanho da VM para os workers"
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Nome de usuário admin"
  default     = "codions"
}

variable "admin_password" {
  description = "Senha do usuário admin"
  default     = "C0d1o#4s%"
}

variable "shared_disk_size" {
  description = "Tamanho do disco compartilhado em GB"
  default     = 160
}

variable "ubuntu_image" {
  description = "Imagem do Ubuntu no Azure"
  default     = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}