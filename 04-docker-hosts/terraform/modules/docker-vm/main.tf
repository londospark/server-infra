terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
    }
  }
}

resource "proxmox_vm_qemu" "docker_vm" {
  name        = var.vm_name
  vmid        = var.vmid
  target_node = var.proxmox_node
  desc        = var.description

  # Clone from template
  clone      = var.template
  full_clone = false

  # CPU and memory
  cores   = var.cores
  sockets = 1
  memory  = var.memory
  cpu     = "host"

  # Boot order
  boot    = "order=scsi0"
  agent   = 1
  onboot  = true
  oncreate = true

  # Disk
  disks {
    scsi {
      scsi0 {
        disk {
          size    = var.disk_size
          storage = var.proxmox_storage
          iothread = true
        }
      }
    }
    ide {
      ide2 {
        cloudinit {
          storage = var.proxmox_storage
        }
      }
    }
  }

  # Network
  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  # Cloud-init configuration
  ipconfig0  = "ip=${var.ip_address}/24,gw=${var.gateway}"
  nameserver = var.nameserver
  searchdomain = var.domain

  # SSH keys
  sshkeys = var.ssh_public_key

  # Cloud-init user
  ciuser  = "ansible"
  cipassword = "temp-password-change-on-first-login"

  # Tags
  tags = join(";", var.tags)

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
      disks,
    ]
  }
}
