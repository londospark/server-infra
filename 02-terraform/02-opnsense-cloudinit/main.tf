resource "proxmox_vm_qemu" "opnsense" {
  name        = var.opnsense_vm_name
  target_node = var.proxmox_node
  vmid        = var.opnsense_vm_vmid
  clone       = var.opnsense_template_name
  full_clone  = true

  # VM Resources
  cores   = var.opnsense_cores
  sockets = var.opnsense_sockets
  memory  = var.opnsense_memory
  
  # Boot configuration
  bootdisk = "scsi0"
  boot     = "order=scsi0"
  
  # QEMU Guest Agent
  agent = 1
  
  # Serial console
  serial {
    id   = 0
    type = "socket"
  }
  
  # Disk configuration
  disk {
    type    = "scsi"
    storage = var.opnsense_storage
    size    = var.opnsense_disk_size
    format  = "raw"
    ssd     = 1
  }
  
  # WAN Network Interface (vtnet0)
  network {
    model  = "virtio"
    bridge = var.wan_bridge
    tag    = var.wan_vlan_tag == 0 ? -1 : var.wan_vlan_tag
  }
  
  # LAN Network Interface (vtnet1)
  network {
    model  = "virtio"
    bridge = var.lan_bridge
    tag    = var.lan_vlan_tag == 0 ? -1 : var.lan_vlan_tag
  }
  
  # Cloud-init configuration
  os_type    = "l26"  # Linux 2.6+ kernel (FreeBSD compatible)
  ipconfig0  = var.wan_ip_config
  ipconfig1  = var.lan_ip_config
  nameserver = var.nameserver
  sshkeys    = var.ssh_public_key
  ciuser     = "root"
  
  # Lifecycle management
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}
