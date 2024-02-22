# ------------------------------------------------------------------------------
# Data sources
# ------------------------------------------------------------------------------
data "cloudinit_config" "main" {
  part {
    content_type = "text/cloud-config"
    content = yamlencode(
      {
        "packages": ["podman", "catatonit"],
        "write_files": [
          {
            "path": "/etc/containers/registries.conf",
            "content": "[registries.search]\nregistries = ['docker.io']",
            "permissions": "0644"
          },
          {
            "path": "/root/wireguard.yaml",
            "content": "${local.wg_deployment}",
            "permissions": "0600"
          },
          {
            "path": "/root/caddy.yaml",
            "content": "${local.caddy_deployment}",
            "permissions": "0600"
          },
          {
            "path": "/root/Caddyfile",
            "content": "${local.caddyfile}",
            "permissions": "0600"
          }
        ],
        "runcmd": [
          "sysctl -w net.ipv4.ip_forward=1",
          "mkdir -p /etc/wireguard/peer1 && chmod -R 0700 /etc/wireguard",
          "podman kube play /root/wireguard.yaml",
          "podman kube play /root/caddy.yaml"
        ]
      }
    )
  }
}

# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
resource "random_password" "caddy" {
  length  = 16
  special = true
}

# ------------------------------------------------------------------------------
# Local variables
# ------------------------------------------------------------------------------
locals {
  fqdn = join(".", [var.hostname, var.domain_name])

  # Wireguard pod deployment manifest
  wg_deployment = templatefile("${path.module}/assets/wireguard.tmpl", {
    fqdn           = local.fqdn
    wg_subnet_cidr = var.wg_subnet_cidr
  })

  # Caddy pod deployment manifest
  caddy_deployment = file("${path.module}/assets/caddy.tmpl")

  # Caddy pod Caddyfile with TLS and HTTP authentication
  caddyfile = <<-EOF
    ${var.cloudflare_https ? "http://:80" : local.fqdn} {
      handle_path /* {
        basicauth /* {
          wg ${random_password.caddy.bcrypt_hash}
        }
        root * /usr/share/caddy
        file_server
      }
    }
    EOF
}
