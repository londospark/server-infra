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

# OPNsense template created from nano image
variable "opnsense_template_name" {
  type        = string
  description = "The name of the OPNsense template VM to clone from (created from nano image)"
  default     = "opnsense-template"
}
