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

variable "ssh_private_key" {
  description = "Path to SSH private key for Proxmox root user"
  type        = string
  default     = "~/.ssh/id_ed25519"
}
