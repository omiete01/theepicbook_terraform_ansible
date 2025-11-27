output "epicbook_IP" {
  value = azurerm_linux_virtual_machine.epicbook_vm.public_ip_address
}

output "mysql_endpoint" {
  value = azurerm_mysql_flexible_server.mysql_server.fqdn
}