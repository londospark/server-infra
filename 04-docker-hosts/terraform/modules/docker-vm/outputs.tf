output "vmid" {
  description = "VM ID"
  value       = proxmox_vm_qemu.docker_vm.vmid
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
  value       = proxmox_vm_qemu.docker_vm.name
}
