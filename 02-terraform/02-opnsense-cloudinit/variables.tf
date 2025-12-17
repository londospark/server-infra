# Proxmox connection variables
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://192.168.1.2:8006/api2/json"
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

# OPNsense template variables
variable "opnsense_template_name" {
  description = "Name of the OPNsense cloud-init template"
  type        = string
  default     = "opnsense-cloudinit-template"
}

# OPNsense VM variables
variable "opnsense_vm_name" {
  description = "Name for the OPNsense VM"
  type        = string
  default     = "opnsense-router"
}

variable "opnsense_vm_vmid" {
  description = "VM ID for OPNsense"
  type        = number
  default     = 100
}

variable "opnsense_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "opnsense_sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "opnsense_memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "opnsense_storage" {
  description = "Proxmox storage for VM disk"
  type        = string
  default     = "local-zfs"
}

variable "opnsense_disk_size" {
  description = "Disk size (e.g., '20G')"
  type        = string
  default     = "20G"
}

# Network configuration
variable "wan_bridge" {
  description = "Bridge for WAN interface"
  type        = string
  default     = "vmbr0"
}

variable "wan_vlan_tag" {
  description = "VLAN tag for WAN (0 for no VLAN)"
  type        = number
  default     = 0
}

variable "lan_bridge" {
  description = "Bridge for LAN interface"
  type        = string
  default     = "vmbr1"
}

variable "lan_vlan_tag" {
  description = "VLAN tag for LAN (0 for no VLAN)"
  type        = number
  default     = 0
}

# Cloud-init configuration
variable "ssh_public_key" {
  description = "SSH public key for root user"
  type        = string
}

variable "wan_ip_config" {
  description = "WAN IP configuration (e.g., 'ip=dhcp' or 'ip=192.168.1.10/24,gw=192.168.1.1')"
  type        = string
  default     = "ip=dhcp"
}

variable "lan_ip_config" {
  description = "LAN IP configuration (e.g., 'ip=192.168.20.1/24')"
  type        = string
  default     = "ip=192.168.20.1/24"
}

variable "nameserver" {
  description = "DNS nameserver"
  type        = string
  default     = "8.8.8.8"
}

variable "searchdomain" {
  description = "DNS search domain"
  type        = string
  default     = ""
}
