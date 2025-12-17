output "docker_hosts" {
  description = "Docker host VMs information"
  value = {
    for vm_name, vm in module.docker_vms : vm_name => {
      vmid       = vm.vmid
      ip_address = vm.ip_address
      fqdn       = vm.fqdn
      ssh_command = "ssh -i ~/.ssh/ansible_homelab ansible@${vm.ip_address}"
    }
  }
}

output "ansible_inventory" {
  description = "Ansible inventory in YAML format"
  value = templatefile("${path.module}/templates/inventory.tpl", {
    vms = {
      for vm_name, vm in module.docker_vms : vm_name => {
        ip_address = vm.ip_address
        role       = split("-", vm_name)[0]
      }
    }
  })
}
