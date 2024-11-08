output "master_public_ip" {
  value = azurerm_public_ip.master_ip.ip_address
}
output "master_private_ip" {
  value = azurerm_network_interface.master_nic.private_ip_address
}

output "worker_public_ips" {
  value = azurerm_public_ip.worker_ip[*].ip_address
}