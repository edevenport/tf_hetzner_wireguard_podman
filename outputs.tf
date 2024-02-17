output "public_ip" {
  value = hcloud_server.wireguard.ipv4_address
}

output wg_qrcode_url {
  value     = "https://${var.domain_name}/peer1.conf"
}

output wg_config_url {
  value     = "https://${var.domain_name}/peer1.png"
}

output http_username {
  value = var.http_username
}

output http_password {
  value     = random_password.caddy.result
  sensitive = true
}
