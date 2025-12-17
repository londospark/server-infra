all:
  children:
    docker_hosts:
      hosts:
%{ for vm_name, vm in vms ~}
        ${vm_name}:
          ansible_host: ${vm.ip_address}
          role: ${vm.role}
%{ endfor ~}
      vars:
        ansible_user: ansible
        ansible_python_interpreter: /usr/bin/python3
        ansible_ssh_private_key_file: ~/.ssh/ansible_homelab
