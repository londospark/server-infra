# Proxmox Post-Boot Configuration

This directory contains Ansible playbooks to configure Proxmox after installation.

## What It Does

The main playbook (`main.yml`) performs the following:

1. **SSH Access**: Installs your SSH public key for passwordless access
2. **Repository Configuration**: Removes enterprise repos and adds no-subscription repos
3. **System Updates**: Updates and upgrades packages
4. **UI Tweaks**: Silences the subscription nag in the web interface
5. **Network Setup**: Configures vmbr1 bridge for internal LAN
6. **Terraform User**: Creates Terraform provisioning user and API token

## Prerequisites

1. Proxmox VE installed and running
2. Network connectivity to Proxmox host
3. SSH keys generated (`~/.ssh/id_ed25519.pub`)
4. Environment variables set (see main README)

## Usage

Run all configuration steps:
```bash
make proxmox-setup
```

Or run specific sections using tags:
```bash
# Only setup SSH
ansible-playbook -i inventory site.yml --tags ssh

# Only configure repos  
ansible-playbook -i inventory site.yml --tags repos

# Only setup network
ansible-playbook -i inventory site.yml --tags network

# Only create Terraform user
ansible-playbook -i inventory site.yml --tags terraform
```

## Storage Detection

To see available storage options on your Proxmox host:
```bash
make detect-storage
```

This helps you choose the correct storage for OPNsense deployment.

## Files

- `main.yml` - Main consolidated playbook
- `detect-storage.yml` - Helper to show available Proxmox storage
