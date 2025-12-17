# OPNsense Deployment

This directory contains Ansible playbooks for deploying and configuring OPNsense on Proxmox using cloud-init.

## Prerequisites

- OPNsense cloud-init image built by Packer (from `03-opnsense-image`)
- Proxmox host accessible and bootstrapped
- SSH access to Proxmox configured
- Environment variables set (see below)

## Environment Variables

Create a `.env` file or export these variables:

```bash
# Proxmox Storage (default: local-lvm)
export OPNSENSE_STORAGE="local-lvm"

# OPNsense Template VM ID (default: 9000)
export OPNSENSE_TEMPLATE_VMID="9000"

# OPNsense VM ID (default: 100)
export OPNSENSE_VMID="100"

# OPNsense LAN Network (default: 10.0.0.1/24)
export OPNSENSE_LAN_IP="10.0.0.1"
export OPNSENSE_LAN_MASK="24"

# OPNsense WAN Configuration (default: dhcp)
export OPNSENSE_WAN_IP="dhcp"  # or static IP like "192.168.1.75/24"
export OPNSENSE_WAN_GW="192.168.1.1"  # required if static

# OPNsense Admin Credentials
export OPNSENSE_ADMIN_USER="admin"
export OPNSENSE_ADMIN_PASSWORD="your-secure-password"

# SSH Key Path (default: ~/.ssh/id_ed25519.pub)
export SSH_PUBLIC_KEY="$HOME/.ssh/id_ed25519.pub"
```

## Playbooks

### deploy-template.yml
Uploads the Packer-built image to Proxmox and creates a template VM.

### clone-and-configure.yml
Clones the template, configures networking, and sets up the admin user.

## Usage

From the repository root:

```bash
# Build image and deploy complete OPNsense setup
make opnsense-vm

# Or run steps individually:
make packer-image          # Build the image
make opnsense-template     # Deploy template to Proxmox
make opnsense-vm          # Clone and configure VM
```

## Network Configuration

The deployment creates:
- **WAN interface (net0)**: Connected to vmbr0 (Proxmox management network)
- **LAN interface (net1)**: Connected to vmbr1 (Internal VM network)

### Accessing VMs behind OPNsense

To access VMs on the OPNsense LAN (10.0.0.0/24) from your home network:

1. Add a static route on your home router:
   - Network: `10.0.0.0/24`
   - Gateway: Proxmox IP (e.g., `192.168.1.2`)

2. Or add the route on your laptop:
   ```bash
   # Linux/Mac
   sudo ip route add 10.0.0.0/24 via 192.168.1.2
   
   # Windows (PowerShell as Admin)
   route add 10.0.0.0 mask 255.255.255.0 192.168.1.2
   ```

## Admin Access

After deployment:
- **Web UI**: https://10.0.0.1 (or WAN IP if configured)
- **Username**: Value of `OPNSENSE_ADMIN_USER` (default: admin)
- **Password**: Value of `OPNSENSE_ADMIN_PASSWORD`
- **SSH**: `ssh root@10.0.0.1` (uses your SSH key)

## Troubleshooting

### Can't access OPNsense web UI
1. Verify VM is running: `ssh root@<proxmox-ip> qm status <vmid>`
2. Check if cloud-init completed: `ssh -J root@<proxmox-ip> root@10.0.0.1`
3. Verify static route is configured on your router/laptop

### Wrong username or password
Re-run the password configuration:
```bash
make opnsense-vm
```

The playbook is idempotent and will reconfigure the admin user.
