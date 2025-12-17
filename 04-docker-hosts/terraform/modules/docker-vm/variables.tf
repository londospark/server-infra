variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vmid" {
  description = "VM ID"
  type        = number
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
}

variable "memory" {
  description = "Memory in MB"
  type        = number
}

variable "disk_size" {
  description = "Disk size (e.g., '100G')"
  type        = string
}

variable "ip_address" {
  description = "Static IP address"
  type        = string
}

variable "description" {
  description = "VM description"
  type        = string
}

variable "tags" {
  description = "VM tags"
  type        = list(string)
  default     = []
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "proxmox_storage" {
  description = "Storage pool name"
  type        = string
}

variable "template" {
  description = "Template to clone from"
  type        = string
}

variable "gateway" {
  description = "Network gateway"
  type        = string
}

variable "nameserver" {
  description = "DNS nameserver"
  type        = string
}

variable "domain" {
  description = "Domain name"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}
