output "nginx_ingress_ip_ip_address" {
  value = azurerm_public_ip.nginx_ingress_ip.ip_address
}