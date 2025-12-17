output "opnsense_vm_id" {
  description = "The VM ID of the OPNsense instance"
  value       = proxmox_vm_qemu.opnsense.vmid
}

output "opnsense_vm_name" {
  description = "The name of the OPNsense VM"
  value       = proxmox_vm_qemu.opnsense.name
}

output "wan_ip_config" {
  description = "WAN interface IP configuration"
  value       = var.wan_ip_config
}

output "lan_ip_config" {
  description = "LAN interface IP configuration"
  value       = var.lan_ip_config
}

output "instructions" {
  description = "Post-deployment instructions"
  value       = <<-EOT
    OPNsense VM deployed successfully!
    
    VM ID: ${proxmox_vm_qemu.opnsense.vmid}
    VM Name: ${proxmox_vm_qemu.opnsense.name}
    
    To retrieve the root password:
    1. SSH into the VM using your private key
    2. Run: grep "Encrypted password" /var/log/messages | tail -1
    3. Decrypt on your workstation:
       echo "<encrypted-password>" | base64 -d | openssl rsautl -decrypt -inkey ~/.ssh/id_ed25519
    
    Access web interface:
    - Check VM IP in Proxmox console or via: qm guest exec ${proxmox_vm_qemu.opnsense.vmid} -- ifconfig
  EOT
}
