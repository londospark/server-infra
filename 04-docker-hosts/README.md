# Docker Hosts Infrastructure

This directory contains Terraform and Ansible configurations for deploying and managing Docker host VMs.

## Architecture

```
Proxmox + OPNsense
└── LAN (10.0.0.0/24)
    ├── dev-host      (10.0.0.21) - Development apps + public hosting
    ├── home-host     (10.0.0.22) - Home management (Grocy, Mealie, etc.)
    └── projects-host (10.0.0.23) - Project management tools
```

## Prerequisites

1. **SSH Key for automation:**
   ```bash
   ssh-keygen -t ed25519 -C "ansible-homelab" -f ~/.ssh/ansible_homelab
   ```

2. **Environment variables** (add to your `.envrc`):
   ```bash
   # Terraform variables (should already exist)
   export TF_VAR_proxmox_api_endpoint="https://192.168.1.2:8006/api2/json"
   export TF_VAR_proxmox_api_token_id="terraform-prov@pve!tf-token"
   export TF_VAR_proxmox_api_token_secret="your-token-secret"
   
   # Docker hosts configuration
   export TF_VAR_proxmox_node="pve"
   export TF_VAR_proxmox_storage="local-zfs"
   export TF_VAR_ssh_public_key="$(cat ~/.ssh/ansible_homelab.pub)"
   export TF_VAR_gateway="10.0.0.1"
   export TF_VAR_nameserver="10.0.0.1"
   
   # Cloudflare tunnels (optional, for public access)
   export CF_TUNNEL_TOKEN_DEV="your-dev-tunnel-token"
   export CF_TUNNEL_TOKEN_PROJECTS="your-projects-tunnel-token"
   ```

3. **Fedora Cloud Template** on Proxmox:
   ```bash
   # Download Fedora 41 cloud image
   wget https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2
   
   # Create template on Proxmox
   ssh root@192.168.1.2
   qm create 9041 --name fedora-41-cloud --memory 2048 --net0 virtio,bridge=vmbr1
   qm importdisk 9041 Fedora-Cloud-Base-Generic-41-1.4.x86_64.qcow2 local-zfs
   qm set 9041 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-9041-disk-0
   qm set 9041 --ide2 local-zfs:cloudinit
   qm set 9041 --boot c --bootdisk scsi0
   qm set 9041 --serial0 socket --vga serial0
   qm set 9041 --agent enabled=1
   qm template 9041
   ```

## Quick Start

```bash
# Complete setup (everything)
make all

# Or step-by-step:
make init        # Initialize Terraform
make apply       # Create VMs
make configure   # Configure with Ansible
make deploy      # Deploy application stacks
```

## Management Commands

```bash
make help              # Show all commands
make plan              # Preview infrastructure changes
make test              # Test Ansible connectivity
make status            # Show VM information

# Deploy specific stacks
make deploy-dev        # Dev apps only
make deploy-home       # Home management only
make deploy-projects   # Project tools only

# SSH to VMs
make ssh-dev
make ssh-home
make ssh-projects
```

## Deployed Applications

### home-host (10.0.0.22)
- **Grocy** - Grocery & household management (http://10.0.0.22 or http://grocy.home.lan)
- **Mealie** - Recipe management
- **Paperless-ngx** - Document management
- **Traefik** - Reverse proxy (dashboard: http://traefik.home-host.home.lan:8080)

### dev-host (10.0.0.21)
- **Traefik** - Reverse proxy
- **Portainer** - Docker management UI
- **Cloudflare Tunnel** - Public access (if configured)
- Your development applications

### projects-host (10.0.0.23)
- **Gitea** - Git hosting
- **Vikunja** - Project management
- **Traefik** - Reverse proxy
- **Cloudflare Tunnel** - Selective public access

## Accessing Services

### From LAN
- Grocy: http://10.0.0.22 or http://grocy.home.lan
- All Traefik dashboards: http://traefik.[hostname].home.lan:8080

### Remote Access (via WireGuard VPN)
See `../05-opnsense-wireguard/README.md` for VPN setup

## Scaling

To add more Docker hosts, edit `terraform/main.tf`:

```hcl
locals {
  vms = {
    # ... existing VMs ...
    media-host = {
      vmid       = 124
      cores      = 4
      memory     = 8192
      disk_size  = "200G"
      ip_address = "10.0.0.24"
      description = "Media server"
      tags       = ["docker", "media"]
    }
  }
}
```

Then run:
```bash
make apply      # Create new VM
make configure  # Configure it
```

## Backup Strategy

1. **VM Snapshots** (before updates):
   ```bash
   ssh root@192.168.1.2 "qm snapshot 121 before-update"
   ```

2. **Docker Volume Backups**:
   ```bash
   ssh ansible@10.0.0.22 "sudo tar -czf /tmp/grocy-backup.tar.gz /opt/apps/grocy/data"
   ```

3. **Configuration** (this repo):
   All configurations are in Git!

## Troubleshooting

### VMs not accessible after creation
```bash
# Check cloud-init status
ssh ansible@10.0.0.21 "sudo cloud-init status"

# View cloud-init logs
ssh ansible@10.0.0.21 "sudo cat /var/log/cloud-init-output.log"
```

### Docker containers not starting
```bash
# Check Docker logs
ssh ansible@10.0.0.22 "docker ps -a"
ssh ansible@10.0.0.22 "docker logs grocy"

# Check compose status
ssh ansible@10.0.0.22 "cd /opt/apps/grocy && docker compose ps"
```

### Ansible connectivity issues
```bash
# Test connectivity
make test

# Check SSH key
ssh -i ~/.ssh/ansible_homelab ansible@10.0.0.21

# Verify firewall
ssh ansible@10.0.0.21 "sudo firewall-cmd --list-all"
```

## Maintenance

### Update system packages
```bash
cd ansible
ansible-playbook -i inventory/hosts.yml playbooks/update-system.yml
```

### Restart a stack
```bash
ssh ansible@10.0.0.22
cd /opt/apps/grocy
docker compose restart
```

## Security Notes

- All VMs are behind OPNsense firewall
- SSH key-only authentication (no passwords)
- Automatic security updates enabled
- Firewalld running on all hosts
- Docker containers on isolated network

## Next Steps

1. Set up WireGuard VPN: `cd ../05-opnsense-wireguard`
2. Configure Cloudflare tunnels for public access
3. Add your development applications to dev-host
4. Customize application stacks in `ansible/stacks/`
