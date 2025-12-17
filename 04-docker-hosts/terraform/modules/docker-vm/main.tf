terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

resource "proxmox_virtual_environment_vm" "docker_vm" {
  name        = var.vm_name
  vm_id       = var.vmid
  node_name   = var.proxmox_node
  description = var.description

  # Clone from template
  clone {
    vm_id = var.template_vmid
  }

  # CPU and memory
  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  # Agent
  agent {
    enabled = true
  }

  # Boot and startup
  on_boot = true

  # Disk
  disk {
    datastore_id = var.proxmox_storage
    interface    = "scsi0"
    size         = parseint(replace(var.disk_size, "G", ""), 10)
    file_format  = "raw"
  }

  # Network
  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }

  # Cloud-init
  initialization {
    datastore_id = var.proxmox_storage

    ip_config {
      ipv4 {
        address = "${var.ip_address}/24"
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.nameserver]
      domain  = var.domain
    }

    user_account {
      username = "ansible"
      keys     = [var.ssh_public_key]
    }
  }

  # Tags
  tags = var.tags
}
