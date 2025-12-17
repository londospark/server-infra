terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_endpoint
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true
  ssh {
    agent       = false
    username    = "root"
    private_key = file(pathexpand(var.ssh_private_key))
  }
}

resource "proxmox_virtual_environment_download_file" "fedora_cloud_image" {
  node_name    = var.proxmox_node
  content_type = "iso"
  datastore_id = "local"

  url = "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2"

  file_name           = "fedora-41-cloud-1.4.img"
  overwrite           = false
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "fedora_template" {
  node_name = var.proxmox_node
  vm_id     = 9041
  name      = "fedora-41-cloud"

  template = true

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }

  disk {
    datastore_id = var.proxmox_storage
    interface    = "scsi0"
    file_id      = proxmox_virtual_environment_download_file.fedora_cloud_image.id
    size         = 32
  }

  serial_device {}

  boot_order = ["scsi0"]

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = var.proxmox_storage
  }

  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }
}

output "template_id" {
  value = proxmox_virtual_environment_vm.fedora_template.vm_id
}

output "template_name" {
  value = proxmox_virtual_environment_vm.fedora_template.name
}
