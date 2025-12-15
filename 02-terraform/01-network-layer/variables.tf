variable "proxmox_api_endpoint" {
  type = string
}

variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

# Optional: Customize if you downloaded a different version
variable "opnsense_iso" {
  type        = string
  description = "The OPNsense ISO image to use for the VM installation."
}
