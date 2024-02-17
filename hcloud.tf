# ------------------------------------------------------------------------------
# Data sources
# ------------------------------------------------------------------------------
data "cloudinit_config" "cloud_config" {
  part {
    content_type = "text/cloud-config"
    content      = yamlencode(
      {
        "packages": ["podman"],
        "write_files": [
          {
            "path": "/etc/containers/registries.conf",
            "content": "[registries.search]\nregistries = ['docker.io']"
            "permissions": "0644"
          },
          {
            "path": "/root/Caddyfile",
            "content": "${local.caddyfile}",
            "permissions": "0600"
          }
        ],
        "runcmd": [
          "mkdir /etc/wireguard && chmod 0700 /etc/wireguard",
		  "sysctl -w net.ipv4.conf.all.src_valid_mark=1",
          "podman run -d --name wireguard --cap-add=NET_ADMIN --cap-add=NET_RAW -p 51820:51820/udp -v /etc/wireguard:/config --env PUID=1000 --env PGID=1000 --env TZ=America/Los_Angeles --env SERVERPORT=51820 --env PEERS=1 --env PEERDNS=auto --env INTERNAL_SUBNET=192.168.2.0/24 --env ALLOWEDIPS=0.0.0.0/0 --env LOG_CONFS=true --sysctl net.ipv4.conf.all.src_valid_mark=1 --sysctl net.ipv4.conf.all.forwarding=1 linuxserver/wireguard",
          "podman run -d --name caddy --cap-add=NET_ADMIN -p 80:80 -p 443:443 -v caddy_data:/data -v /etc/wireguard/peer1:/usr/share/caddy -v /root/Caddyfile:/etc/caddy/Caddyfile caddy"
        ]
      }
    )
  }
}

# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
resource "random_password" "caddy" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "hcloud_ssh_key" "default" {
  name       = "wireguard-server"
  public_key = module.ssh_keygen.public_key
}

resource "hcloud_firewall" "wireguard" {
  name = "wireguard-fw"

  # Allow incoming ICMP (ping, etc.)
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # Allow incoming SSH
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # Allow incoming HTTP
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # Allow incoming HTTPS
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # Allow incoming Wireguard connections
  rule {
    direction = "in"
    protocol  = "udp"
    port      = "51820"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_server" "wireguard" {
  name         = var.server_name
  image        = var.image
  server_type  = var.server_type
  datacenter   = var.datacenter
  user_data    = data.cloudinit_config.cloud_config.rendered
  ssh_keys     = [ hcloud_ssh_key.default.name ]
  firewall_ids = [hcloud_firewall.wireguard.id]

  labels = {
    "app" : "wireguard"
  }

  connection {
    type        = "ssh"
    user        = var.image_username
    host        = hcloud_server.wireguard.ipv4_address
    private_key = module.ssh_keygen.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
  }
}

# ------------------------------------------------------------------------------
# Local variables
# ------------------------------------------------------------------------------
locals {
  wg_netmask_bits = split("/", var.wg_subnet_cidr)[1]
  caddyfile = <<-EOF
    wg.edevenport.dev {
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
