# ------------------------------------------------------------------------------
# Providers
# ------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.7"
}

# ------------------------------------------------------------------------------
# Modules
# ------------------------------------------------------------------------------
module "ssh_keygen" {
  source = "github.com/edevenport/tf_ssh_keygen"

  ssh_key_path = var.secrets_path
}

module "infrastructure" {
  source = "github.com/edevenport/tf_hcloud"

  app_name     = var.app_name
  datacenter   = var.datacenter
  hcloud_token = var.hcloud_token
  image        = var.image
  server_name  = var.server_name
  server_type  = var.server_type
  user_data    = data.cloudinit_config.main.rendered

  ssh_private_key = module.ssh_keygen.private_key
  ssh_public_key  = module.ssh_keygen.public_key
}

module "cloudflare_dns" {
  source = "github.com/edevenport/tf_cloudflare_dns"

  cloudflare_token = var.cloudflare_token
  hostname         = var.hostname
  domain_name      = var.domain_name
  proxied          = var.cloudflare_https

  ipv4_address = module.infrastructure.ipv4_address
  ipv6_address = module.infrastructure.ipv6_address
}
