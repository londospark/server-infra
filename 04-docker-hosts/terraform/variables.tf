variable "proxmox_api_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "proxmox_storage" {
  description = "Proxmox storage pool"
  type        = string
  default     = "local-zfs"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = "10.0.0.1"
}

variable "nameserver" {
  description = "DNS nameserver"
  type        = string
  default     = "10.0.0.1"
}

variable "domain" {
  description = "Internal domain name"
  type        = string
  default     = "home.lan"
}

variable "fedora_template" {
  description = "Fedora cloud template name"
  type        = string
  default     = "fedora-41-cloud"
}
