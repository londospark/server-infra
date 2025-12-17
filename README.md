# Server Infrastructure

Automated Proxmox and OPNsense deployment using Packer, Ansible, and cloud-init.

## Prerequisites

- **Packer** - For building OPNsense image
- **Ansible** - For automation
- **Bitwarden CLI** (`bw`) - For secret management
- **SSH key** - `~/.ssh/id_ed25519.pub`

## Environment Setup

Copy the example environment file and configure:

```bash
cp .envrc.example .envrc
# Edit .envrc with your settings
direnv allow  # if using direnv
```

Required environment variables:
- `PROXMOX_HOST` - Proxmox IP address
- `PROXMOX_STORAGE` - Storage name (e.g., local-lvm, local-zfs)
- `OPNSENSE_ADMIN_PASSWORD` - WebUI password
- `OPNSENSE_LAN_IP` - LAN interface IP (default: 10.0.0.1/24)
- `OPNSENSE_WAN_IP` - WAN IP (dhcp or static IP)

## Quick Start

1. **Create Proxmox Installer USB**
   ```bash
   make install-proxmox
   ```

2. **Configure Proxmox**
   ```bash
   make proxmox-config
   ```

3. **Deploy OPNsense**
   ```bash
   make opnsense-setup
   ```

## Access

**OPNsense WebUI:** https://10.0.0.1
- Username: admin
- Password: (from `$OPNSENSE_ADMIN_PASSWORD`)

**Note:** Add static route on your home router:
- Network: `10.0.0.0/24`
- Gateway: Your Proxmox IP

## Project Structure

```
├── 00-proxmox-installer/    # Proxmox USB installer
├── 01-opnsense-image/       # Packer OPNsense cloud-init image
├── 02-opnsense-deployment/  # Ansible OPNsense deployment
└── 03-proxmox-config/       # Ansible Proxmox configuration
```

## Makefile Targets

Run `make help` to see all available targets.
