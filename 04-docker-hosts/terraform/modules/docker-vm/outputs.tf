output "vmid" {
  description = "VM ID"
  value       = proxmox_virtual_environment_vm.docker_vm.vm_id
}

output "ip_address" {
  description = "VM IP address"
  value       = var.ip_address
}

output "fqdn" {
  description = "Fully qualified domain name"
  value       = "${var.vm_name}.${var.domain}"
}

output "name" {
  description = "VM name"
  value       = proxmox_virtual_environment_vm.docker_vm.name
}
