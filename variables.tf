variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_token" {
  type      = string
  sensitive = true
}

variable "app_name" {
  type    = string
  default = "wireguard"
}

variable "hostname" {
  type    = string
  default = "wg"
}

variable "http_username" {
  type    = string
  default = "wg"
}

variable "wg_subnet_cidr" {
  type    = string
  default = "192.168.10.0/24"
}

variable "cloudflare_https" {
  type    = bool
  default = false
}

variable "datacenter" {}
variable "domain_name" {}
variable "image" {}
variable "secrets_path" {}
variable "server_name" {}
variable "server_type" {}
