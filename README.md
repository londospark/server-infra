# Server Infrastructure Automation

Comprehensive infrastructure-as-code for a complete homelab setup with Proxmox, OPNsense, and Docker hosts.

## 🏗️ Architecture Overview

```
Internet
    ↓
WAN Interface (192.168.1.0/24)
    ↓
Proxmox Host (192.168.1.2)
    ├── OPNsense Firewall (VM)
    │   ├── WAN: 192.168.1.1
    │   ├── LAN: 10.0.0.1
    │   └── VPN: 10.0.100.1 (WireGuard)
    │
    └── LAN Network (10.0.0.0/24)
        ├── dev-host      (10.0.0.21) - Development + public apps
        ├── home-host     (10.0.0.22) - Home management (Grocy!)
        └── projects-host (10.0.0.23) - Project management tools
```

## 📁 Directory Structure

```
server-infra/
├── 00-proxmox-installer/      # Proxmox VE installation
├── 01-proxmox-config/          # Proxmox initial configuration
├── 02-opnsense-image/          # Build OPNsense cloud image with Packer
├── 03-opnsense-deployment/     # Deploy OPNsense VM
├── 04-docker-hosts/            # 🆕 Docker host VMs (Terraform + Ansible)
├── 05-opnsense-wireguard/      # 🆕 WireGuard VPN setup
└── setup-*.sh                  # OS-specific setup scripts
```

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Set up your machine (choose one)
./setup-arch.sh      # Arch Linux
./setup-ubuntu.sh    # Ubuntu
./setup-fedora.sh    # Fedora

# Configure environment
cp .envrc.example .envrc
# Edit .envrc with your settings
direnv allow

# Create SSH key for automation
ssh-keygen -t ed25519 -C "ansible-homelab" -f ~/.ssh/ansible_homelab
```

### 2. Deploy Infrastructure (In Order)

1. **Install Proxmox** → `cd 00-proxmox-installer && make run`
2. **Configure Proxmox** → `cd 01-proxmox-config && make bootstrap`
3. **Build OPNsense** → `cd 02-opnsense-image && make build`
4. **Deploy OPNsense** → `cd 03-opnsense-deployment && make deploy`
5. **Deploy Docker Hosts** → `cd 04-docker-hosts && make all` ⭐ NEW!
6. **Set Up VPN** → `cd 05-opnsense-wireguard && make setup-vpn` ⭐ NEW!

## 🎯 What You Get

- **Grocy** - Household management (groceries, recipes, tasks)
- **Mealie** - Recipe manager  
- **Paperless-ngx** - Document management
- **Gitea** - Self-hosted Git
- **Vikunja** - Project management
- **Traefik** - Reverse proxy with auto-SSL
- **WireGuard VPN** - Secure remote access
- **Full automation** - Reproducible infrastructure

## 📚 Documentation

- [00-proxmox-installer/README.md](00-proxmox-installer/README.md) - Proxmox installation
- [01-proxmox-config/README.md](01-proxmox-config/README.md) - Proxmox configuration
- [02-opnsense-image/README.md](02-opnsense-image/README.md) - OPNsense image building
- [03-opnsense-deployment/README.md](03-opnsense-deployment/README.md) - OPNsense deployment
- [04-docker-hosts/README.md](04-docker-hosts/README.md) ⭐ NEW! - Docker hosts setup
- [05-opnsense-wireguard/README.md](05-opnsense-wireguard/README.md) ⭐ NEW! - WireGuard VPN

## License

MIT
