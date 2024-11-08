output "master_public_ip" {
  value = azurerm_public_ip.master_ip.ip_address
}

output "worker_public_ips" {
  value = azurerm_public_ip.worker_ip[*].ip_address
}

output "username" {
  value = azurerm_storage_account.sa.name
}

output "share" {
  value = azurerm_storage_share.ss.name
}

output "mount_password" {
  value = azurerm_storage_account.sa.primary_access_key
  sensitive = true
}