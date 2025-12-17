provider "proxmox" {
  pm_api_url                  = var.proxmox_api_endpoint
  pm_api_token_id             = var.proxmox_api_token_id
  pm_api_token_secret         = var.proxmox_api_token_secret
  pm_tls_insecure             = true
  pm_minimum_permission_check = false
}

/*
resource "proxmox_vm_qemu" "opnsense" {
  name        = "opnsense-router"
  target_node = "pve"
  vmid        = 100

  # Clone from prebuilt OPNsense template (created from nano image)
  clone      = var.opnsense_template_name
  full_clone = true

  # Let the template fully own disk layout; avoid Terraform trying to detach the cloned disk on re-apply
  lifecycle {
    ignore_changes = [disk, disks]
  }

  # Basic Config
  os_type            = "other"
  agent              = 0
  start_at_node_boot = true

  # CPU & Memory
  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }
  memory = 4096
  scsihw = "virtio-scsi-pci"

  # --- NETWORK: Requires explicit 'id' ---

  # WAN (vmbr0 -> Internet)
  network {
    id       = 0
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  # LAN (vmbr1 -> Internal Network)
  network {
    id       = 1
    model    = "virtio"
    bridge   = "vmbr1"
    firewall = false
  }
}
*/
