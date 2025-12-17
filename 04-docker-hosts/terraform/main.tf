locals {
  vms = {
    dev-host = {
      vmid        = 121
      cores       = 4
      memory      = 8192
      disk_size   = "100G"
      ip_address  = "10.0.0.21"
      description = "Development and public web hosting"
      tags        = ["docker", "public", "dev"]
    }
    home-host = {
      vmid        = 122
      cores       = 2
      memory      = 4096
      disk_size   = "50G"
      ip_address  = "10.0.0.22"
      description = "Home management applications"
      tags        = ["docker", "private", "home"]
    }
    projects-host = {
      vmid        = 123
      cores       = 4
      memory      = 6144
      disk_size   = "80G"
      ip_address  = "10.0.0.23"
      description = "Project management tools"
      tags        = ["docker", "mixed", "projects"]
    }
  }
}

module "docker_vms" {
  source   = "./modules/docker-vm"
  for_each = local.vms

  vm_name     = each.key
  vmid        = each.value.vmid
  cores       = each.value.cores
  memory      = each.value.memory
  disk_size   = each.value.disk_size
  ip_address  = each.value.ip_address
  description = each.value.description
  tags        = each.value.tags

  proxmox_node    = var.proxmox_node
  proxmox_storage = var.proxmox_storage
  template_vmid   = var.fedora_template_vmid
  gateway         = var.gateway
  nameserver      = var.nameserver
  domain          = var.domain
  ssh_public_key  = var.ssh_public_key
}
