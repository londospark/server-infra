# OPNsense Cloud-Init Terraform Module

This Terraform module deploys OPNsense VMs from a cloud-init enabled template on Proxmox VE.

## Prerequisites

1. **OPNsense cloud-init template** must exist in Proxmox
   - Build with Packer: `cd ../../03-opnsense-image && packer build .`
   - Deploy to Proxmox: `ansible-playbook ../../01-post-boot-ansible/07-deploy-opnsense-cloudinit.yml`

2. **Terraform** (v1.0+)
   ```bash
   brew install terraform  # macOS
   # Or download from https://www.terraform.io/downloads
   ```

3. **Proxmox API Token** (created by bootstrap playbook)

## Quick Start

### 1. Initialize Terraform

```bash
cd 02-terraform/02-opnsense-cloudinit
terraform init
```

### 2. Configure Variables

Copy the example file and edit:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
proxmox_api_token_id     = "terraform@pam!terraform-token"
proxmox_api_token_secret = "your-secret-here"
ssh_public_key           = "ssh-rsa AAAAB3NzaC1..."
```

### 3. Plan and Apply

```bash
terraform plan
terraform apply
```

## Variables

### Required Variables

- `proxmox_api_token_id` - Proxmox API token ID
- `proxmox_api_token_secret` - Proxmox API token secret (sensitive)
- `ssh_public_key` - SSH public key for root access

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `proxmox_api_url` | `https://192.168.1.2:8006/api2/json` | Proxmox API endpoint |
| `proxmox_node` | `pve` | Proxmox node name |
| `opnsense_template_name` | `opnsense-cloudinit-template` | Template to clone from |
| `opnsense_vm_name` | `opnsense-router` | VM name |
| `opnsense_vm_vmid` | `100` | VM ID |
| `opnsense_cores` | `2` | CPU cores |
| `opnsense_memory` | `4096` | Memory in MB |
| `opnsense_disk_size` | `20G` | Disk size |
| `wan_bridge` | `vmbr0` | WAN bridge |
| `lan_bridge` | `vmbr1` | LAN bridge |
| `wan_vlan_tag` | `0` | WAN VLAN (0 = no VLAN) |
| `lan_vlan_tag` | `0` | LAN VLAN (0 = no VLAN) |
| `wan_ip_config` | `ip=dhcp` | WAN IP configuration |
| `lan_ip_config` | `ip=192.168.20.1/24` | LAN IP configuration |
| `nameserver` | `8.8.8.8` | DNS nameserver |

## Network Configuration

### DHCP on WAN

```hcl
wan_ip_config = "ip=dhcp"
```

### Static IP on WAN

```hcl
wan_ip_config = "ip=192.168.1.10/24,gw=192.168.1.1"
wan_bridge    = "vmbr0"
wan_vlan_tag  = 10  # Optional VLAN
```

### Multiple Interfaces

The module automatically creates two network interfaces:
- **vtnet0** (WAN) - Connected to `wan_bridge`
- **vtnet1** (LAN) - Connected to `lan_bridge`

## Cloud-Init Integration

The VM is configured via cloud-init on first boot:

1. **SSH Key Injection** - Your public key is added to root's authorized_keys
2. **Network Configuration** - Interfaces configured per ipconfig settings
3. **Password Generation** - Random root password generated and encrypted
4. **First Boot Script** - Runs OPNsense-specific initialization

### Retrieving Root Password

After deployment:

```bash
# SSH into the VM
ssh root@<vm-ip>

# Get encrypted password
grep "Encrypted password" /var/log/messages | tail -1

# On your workstation, decrypt with your private key
echo "<encrypted-password>" | base64 -d | openssl rsautl -decrypt -inkey ~/.ssh/id_ed25519
```

## Outputs

After `terraform apply`, the following outputs are available:

```bash
terraform output opnsense_vm_id      # VM ID
terraform output opnsense_vm_name    # VM name
terraform output wan_ip_config       # WAN configuration
terraform output lan_ip_config       # LAN configuration
terraform output instructions        # Post-deployment instructions
```

## Advanced Usage

### Multiple OPNsense Instances

Use Terraform workspaces or modules:

```hcl
module "opnsense_primary" {
  source = "./02-opnsense-cloudinit"
  
  opnsense_vm_name = "opnsense-primary"
  opnsense_vm_vmid = 100
  wan_ip_config    = "ip=192.168.1.10/24,gw=192.168.1.1"
  lan_ip_config    = "ip=192.168.20.1/24"
}

module "opnsense_backup" {
  source = "./02-opnsense-cloudinit"
  
  opnsense_vm_name = "opnsense-backup"
  opnsense_vm_vmid = 101
  wan_ip_config    = "ip=192.168.1.11/24,gw=192.168.1.1"
  lan_ip_config    = "ip=192.168.20.2/24"
}
```

### VLAN Configuration

```hcl
wan_bridge   = "vmbr0"
wan_vlan_tag = 10  # WAN on VLAN 10

lan_bridge   = "vmbr0"  # Same bridge, different VLAN
lan_vlan_tag = 20  # LAN on VLAN 20
```

### Custom Disk Size

```hcl
opnsense_disk_size = "40G"  # Expand to 40GB
```

## Comparison with Nano Image Approach

| Feature | Cloud-Init Image (This) | Nano Image (Legacy) |
|---------|-------------------------|---------------------|
| Build Method | Packer (automated) | Manual download |
| Cloud-Init | ✅ Full support | ❌ None |
| SSH Keys | ✅ Automated injection | ❌ Manual setup |
| Network Config | ✅ Via cloud-init | ❌ Manual reconfiguration |
| Password | ✅ Auto-generated | 🔧 Pre-set or manual |
| Template Size | ~1.4GB | ~500MB |
| Deployment Speed | Fast (cloud-init) | Slow (manual steps) |
| Automation Ready | ✅ Yes | ⚠️ Requires post-config |

## Troubleshooting

### Template Not Found

```
Error: template 'opnsense-cloudinit-template' not found
```

**Solution**: Deploy the template first:
```bash
cd ../..
ansible-playbook 01-post-boot-ansible/07-deploy-opnsense-cloudinit.yml
```

### Cloud-Init Not Running

Check cloud-init status on the VM:
```bash
ssh root@<vm-ip>
cloud-init status --long
cat /var/log/cloud-init.log
```

### SSH Key Not Working

Verify the key in cloud-init data:
```bash
ssh root@<vm-ip>
cat /root/.ssh/authorized_keys
```

### Network Not Configured

Check Proxmox cloud-init configuration:
```bash
qm cloudinit dump <vmid> user
qm cloudinit dump <vmid> network
```

## Integration with Existing Infrastructure

### With Ansible

Use Ansible to manage post-deployment configuration:

```yaml
- name: Configure OPNsense firewall rules
  hosts: opnsense_routers
  tasks:
    - name: Add firewall rule via API
      uri:
        url: "https://{{ ansible_host }}/api/firewall/filter/addRule"
        method: POST
        user: "{{ api_key }}"
        password: "{{ api_secret }}"
        body_format: json
```

### With CI/CD

```yaml
# GitLab CI example
deploy_opnsense:
  stage: deploy
  script:
    - cd 02-terraform/02-opnsense-cloudinit
    - terraform init
    - terraform apply -auto-approve
  only:
    - main
```

## Cleanup

To destroy the OPNsense VM:

```bash
terraform destroy
```

**Note**: This only removes the VM, not the template.

## Next Steps

1. **Configure OPNsense** - Access web UI and configure firewall rules, VPN, etc.
2. **High Availability** - Deploy multiple instances for HA setup
3. **Automation** - Use Ansible or OPNsense API for configuration management
4. **Monitoring** - Integrate with monitoring tools (Prometheus, Grafana)

## References

- [Proxmox Cloud-Init](https://pve.proxmox.com/wiki/Cloud-Init_Support)
- [OPNsense Documentation](https://docs.opnsense.org/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/)
