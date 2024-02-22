# tf_hetzner_wireguard_podman

## Description

Creates a server on Hetzner Online and deploys Wireguard along with Caddy to serve a single peer config file and QR code. The webserver supports integrated HTTPS or can offload TLS to Cloudflare.

## Usage

Example `terraform.tfvars`

```
hcloud_token          = "HCLOUD_API_TOKEN"
cloudflare_token      = "CLOUDFLARE_API_TOKEN"
cloudflare_https      = false                    // Offload TLS to Cloudflare or use Caddy generated TLS.
app_name              = "APP_NAME"
hostname              = "wg"                     // DNS record added to Cloudflare domain name.
domain_name           = "mydomain.com            // Domain assigned to Cloudflare for automatic DNS assignment.
wg_subnet_cidr        = "192.168.10.0/24"        // Wireguard subnet CIDR.
server_name           = "wireguard"
server_type           = "cpx11"
image                 = "debian-12"
datacenter            = "hil-dc1"
secret_path           = "/path/to/secrets"       // Stores public and private SSH keys.
```

## Notes

* Wireguard configuration may not survive a server reboot at this time.
