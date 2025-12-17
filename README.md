# Server Infrastructure

Automated infrastructure setup for Proxmox with OPNsense firewall.

## Overview

This repository automates the complete setup of a homelab infrastructure:

1. **Proxmox VE** - Hypervisor installation and configuration
2. **OPNsense** - Firewall/router for VM network isolation
3. **VM Network** - Isolated network (10.0.0.0/24) accessible from home network

## Directory Structure

- `00-proxmox-installer/` - Create Proxmox VE installer USB
- `01-post-boot-ansible/` - Proxmox post-installation configuration
- `02-opnsense-image/` - Build OPNsense cloud-init image with Packer
- `03-opnsense-deployment/` - Deploy and configure OPNsense on Proxmox

## Prerequisites

### Software Required

- **Ansible** (>= 2.9)
- **Packer** (>= 1.9)
- **Python 3** with `jq` package
- **SSH access** to Proxmox host

### Environment Setup

1. Copy the example environment file:
   ```bash
   cp .envrc.example .envrc
   ```

2. Edit `.envrc` and set required variables:
   ```bash
   # Required
   export PROXMOX_HOST="192.168.1.2"
   export OPNSENSE_ADMIN_PASSWORD="your-secure-password"
   
   # Optional (defaults shown)
   export OPNSENSE_VERSION="25.7"
   export OPNSENSE_MIRROR="https://mirror.init7.net/opnsense"
   export OPNSENSE_WAN_IP="dhcp"
   export OPNSENSE_WAN_GATEWAY="192.168.1.1"
   export OPNSENSE_LAN_IP="10.0.0.1"
   export OPNSENSE_LAN_MASK="24"
   export PROXMOX_STORAGE="local-lvm"
   ```

3. Load environment variables:
   ```bash
   source .envrc  # or use direnv
   ```

## Quick Start

### Complete Setup

```bash
make opnsense-setup
```

This will:
1. Build OPNsense cloud-init image (~15-20 minutes)
2. Upload image to Proxmox
3. Create template VM (ID 9000)
4. Clone and configure OPNsense VM (ID 100)
5. Set up networking and admin credentials

### Step-by-Step

```bash
# 1. Install Proxmox (if needed)
make install-proxmox

# 2. Configure Proxmox
make proxmox-setup

# 3. Build OPNsense Image
make opnsense-image

# 4. Deploy OPNsense
make opnsense-deploy
```

## Network Architecture

```
Home Network (192.168.1.x)
    ↓
  [Your Router] ← Proxmox vmbr0 (WAN) - OPNsense - vmbr1 (LAN) → VMs (10.0.0.x)
    ↓
 Proxmox Host (192.168.1.2)
```

### Accessing VMs

Add a static route on your home router:
- Network: `10.0.0.0/24`
- Gateway: `192.168.1.2` (Proxmox host)

Then access directly:
- OPNsense WebUI: `https://10.0.0.1`
- VMs: Direct access at `10.0.0.x`

## OPNsense Access

- **WebUI**: `https://10.0.0.1`
- **Username**: `admin`
- **Password**: Value of `OPNSENSE_ADMIN_PASSWORD`
- **SSH**: `ssh -J root@192.168.1.2 root@10.0.0.1`

## Troubleshooting

### Can't access 10.0.0.1

Add route manually:
```bash
# Linux/Mac
sudo ip route add 10.0.0.0/24 via 192.168.1.2

# Windows (PowerShell as Admin)
route add 10.0.0.0 mask 255.255.255.0 192.168.1.2
```

### Clean and Rebuild

```bash
make clean
make opnsense-setup
```

## License

MIT License
