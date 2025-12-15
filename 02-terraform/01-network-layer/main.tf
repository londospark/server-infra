provider "proxmox" {
  pm_api_url                  = var.proxmox_api_endpoint
  pm_api_token_id             = var.proxmox_api_token_id
  pm_api_token_secret         = var.proxmox_api_token_secret
  pm_tls_insecure             = true
  pm_minimum_permission_check = false
}

resource "proxmox_vm_qemu" "opnsense" {
  name        = "opnsense-router"
  target_node = "pve"
  vmid        = 100

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

  # Boot Order
  boot = "order=scsi0;ide2"

  # --- 3.x SYNTAX: Nested 'disks' block ---
  disks {
    # Hard Drive (scsi0)
    scsi {
      scsi0 {
        disk {
          storage = "local-zfs"
          size    = "32G"
          # Fix: Use booleans (true/false) instead of 1/0 or "on"
          iothread   = true
          emulatessd = true # 'ssd' was renamed/aliased to this in some versions
          discard    = true
        }
      }
    }

    # CD-ROM (ide2) - This is where the ISO lives now
    ide {
      ide2 {
        cdrom {
          iso = var.opnsense_iso
        }
      }
    }
  }

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
