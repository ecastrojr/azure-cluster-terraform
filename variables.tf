# Prefixo para nomear recursos no Azure, facilitando a identificação
variable "prefix" {
  description = "Prefixo para nomear recursos"
  default     = "dio"
}

# Localização (região) onde os recursos serão implantados no Azure
variable "location" {
  description = "Localização do Azure para implantar os recursos"
  default     = "East US"
}

# Tamanho (SKU) da VM para o nó master do cluster
variable "master_vm_size" {
  description = "Tamanho da VM para os masters"
  default     = "Standard_B2s"
}

# Tamanho (SKU) da VM para os nós worker do cluster
variable "worker_vm_size" {
  description = "Tamanho da VM para os workers"
  default     = "Standard_B2s"
}

# Nome de usuário admin para acessar as VMs
variable "admin_username" {
  description = "Nome de usuário admin"
  default     = "swarm_admin"
}

# Senha para o usuário admin (apenas para demonstração; para produção, utilize outra abordagem de segurança)
variable "admin_password" {
  description = "Senha do usuário admin"
  default     = "D3v0ps!#"
}

# Caminho local para a chave pública SSH, usada para autenticação nas VMs
variable "ssh_public_key_path" {
  description = "Caminho para sua chave pública SSH local"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}
variable "ssh_private_key_path" {
  description = "Caminho para sua chave privada SSH local"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

# Tamanho do disco compartilhado em gigabytes (GB)
variable "shared_disk_size" {
  description = "Tamanho do disco compartilhado em GB"
  default     = 160
}

variable "share_folder" {
  description = "Caminha absoluto da pasta a ser compartilhada entre nós"
  default = "/opt/docker_share"
}

# Configuração da imagem Ubuntu que será utilizada nas VMs
variable "ubuntu_image" {
  description = "Imagem do Ubuntu no Azure"
  default     = {
    publisher = "Canonical"                  # Publicador da imagem
    offer     = "0001-com-ubuntu-server-jammy" # Oferta específica da imagem
    sku       = "22_04-lts-gen2"             # Versão do Ubuntu (LTS)
    version   = "latest"                     # Última versão disponível
  }
}