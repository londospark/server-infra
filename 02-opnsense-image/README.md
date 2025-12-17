# OPNsense Cloud-Init Image Builder

This directory contains a Packer-based workflow to build cloud-init enabled OPNsense images for Proxmox VE. The resulting image can be used to create OPNsense VMs that support automated deployment via cloud-init.

## Overview

This builder creates a customized OPNsense qcow2 image with:
- **Cloud-init support** - NoCloud datasource for Proxmox
- **QEMU Guest Agent** - Enhanced Proxmox integration  
- **SSH key injection** - Automated via cloud-init
- **Network configuration** - WAN (DHCP or static) and LAN (static) via cloud-init
- **First-boot script** - Automated initial configuration

## Prerequisites

The build requires:
- **Packer** (v1.8+)
- **QEMU/KVM** 
- **curl** and **bzip2**

These are automatically installed by the root Makefile when you run `make deps`.

## Quick Start

### Option 1: Using the Root Makefile (Recommended)

From the project root:

```bash
# Build the image, create template in Proxmox, and deploy VM (all in one)
make opnsense-cloudinit-template opnsense-cloudinit-vm

# Or step by step:
make opnsense-cloudinit-template  # Downloads ISO, builds image with Packer, uploads to Proxmox
make opnsense-cloudinit-vm        # Clones template to create VM
make opnsense-set-password        # Creates admin user for web UI
make opnsense-routing             # Configures routing for homelab access
```

### Option 2: Manual Build

```bash
cd 03-opnsense-image

# Initialize Packer
packer init .

# Download ISO (idempotent - skips if exists)
./get-iso.sh

# Build image
packer build .

# Output: output/opnsense-25.7-proxmox.qcow2
```

## Environment Variables

All variables have sensible defaults:

```bash
# OPNsense version (default: 25.7)
export PKR_VAR_VERSION="25.7"

# Mirror URL (default: https://mirror.init7.net/opnsense)
export PKR_VAR_MIRROR="https://mirror.init7.net/opnsense"

# ISO checksum (auto-calculated if not set)
export PKR_VAR_ISO_CHECKSUM="sha1:e388904d39e4e9604a89111b8410c98474782a41"
```

## What Gets Built

The Packer build:
1. Downloads OPNsense DVD ISO (~500MB)
2. Boots in QEMU/KVM
3. Runs automated installation
4. Installs packages: QEMU guest agent, cloud-init, base64
5. Configures cloud-init datasources
6. Creates first-boot script for SSH key injection
7. Outputs qcow2 image (~1.4GB)

**Build time:** ~15-20 minutes

## Deployment Workflow

The complete setup creates:

1. **Template VM (ID 9000)** - OPNsense cloud-init template
2. **Running VM (ID 100)** - Cloned from template with:
   - WAN interface (eth0) on vmbr0 - DHCP or static IP
   - LAN interface (eth1) on vmbr1 - Static IP (default 10.0.0.1/24)
   - SSH access via root@LAN_IP with your SSH key
   - Admin user for web UI access

## Accessing OPNsense

### SSH Access

```bash
# Direct SSH (requires static route on your router)
ssh -J root@<proxmox-ip> root@<lan-ip>

# Or add to your ~/.ssh/config:
Host opnsense
    HostName <lan-ip>
    User root
    ProxyJump root@<proxmox-ip>
```

### Web UI Access

1. Add static route on your home router:
   ```
   Network: 10.0.0.0/24
   Gateway: <proxmox-ip>
   ```

2. Browse to: `https://10.0.0.1` (or your configured LAN IP)

3. Login with credentials from `make opnsense-set-password`:
   - Default username: `admin`
   - Default password: `opnsense`
   - (Change via env vars `OPNSENSE_ADMIN_USER` and `OPNSENSE_ADMIN_PASSWORD`)

## Customizing the Build

### Change OPNsense Version

```bash
export PKR_VAR_VERSION="25.1"
export PKR_VAR_ISO_CHECKSUM="sha1:YOUR_CHECKSUM"
make packer-rebuild
```

### Modify Default Configuration

Edit `http/config.xml` for:
- Firewall rules
- Interface assignments  
- System settings

### Add Packages

Edit `scripts/post-install.sh`:

```bash
pkg install -y os-wireguard os-haproxy
```

## Idempotent Builds

All operations are idempotent:

```bash
# Safe to run multiple times - skips if already done
make opnsense-cloudinit-template

# Forces rebuild
make packer-clean opnsense-cloudinit-template
```

## Troubleshooting

### Build Hangs or Fails

- Verify QEMU/KVM is installed: `which qemu-system-x86_64`
- Check disk space: need 20GB+ free
- Increase `ssh_timeout` in `opnsense.pkr.hcl`

### Can't Access Web UI

- Verify static route on your router
- Check firewall on OPNsense: SSH in and run `pfctl -d` to temporarily disable
- Verify LAN interface has correct IP: `ifconfig eth1`

### SSH Connection Refused

- Confirm cloud-init ran: `ssh -J root@proxmox root@lan-ip "cat /var/log/cloud-init.log"`
- Verify SSH key is in config: `ssh -J root@proxmox root@lan-ip "grep ssh /conf/config.xml"`
- Check first-boot script ran: `ssh -J root@proxmox root@lan-ip "cat /var/log/messages | grep firstboot"`

## Directory Structure

```
03-opnsense-image/
├── opnsense.pkr.hcl          # Packer build definition
├── get-iso.sh                # ISO download script (idempotent)
├── scripts/
│   ├── base.sh              # Package updates, base config
│   ├── qemu-guest-agent.sh  # QEMU agent
│   ├── cloud-init.sh        # Cloud-init installation
│   └── post-install.sh      # Final hardening
├── http/
│   ├── config.xml           # OPNsense base config
│   └── first-boot.sh        # SSH key injection script
├── iso/                     # Downloaded ISOs (gitignored)
└── output/                  # Built images (gitignored)
```

## Advanced: Manual Deployment to Proxmox

If not using the Ansible playbook:

```bash
# 1. Copy image to Proxmox
scp output/opnsense-25.7-proxmox.qcow2 root@proxmox:/var/lib/vz/template/qcow/

# 2. Create template VM
qm create 9000 --name opnsense-cloudinit-template --memory 2048 --net0 virtio,bridge=vmbr0 --net1 virtio,bridge=vmbr1
qm importdisk 9000 /var/lib/vz/template/qcow/opnsense-25.7-proxmox.qcow2 local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000

# 3. Clone to create VM
qm clone 9000 100 --name opnsense-fw --full
qm set 100 --sshkeys ~/.ssh/id_ed25519.pub
qm set 100 --ipconfig0 ip=dhcp
qm set 100 --ipconfig1 ip=10.0.0.1/24
qm start 100
```

## Resources

- [OPNsense Documentation](https://docs.opnsense.org/)
- [Cloud-init Documentation](https://cloudinit.readthedocs.io/)
- [Packer QEMU Builder](https://developer.hashicorp.com/packer/plugins/builders/qemu)
- [Proxmox Cloud-Init](https://pve.proxmox.com/wiki/Cloud-Init_Support)

## Credits

Based on [open-images/opnsense](https://gitlab.com/open-images/opnsense) by Kevin Allioli and Valentin Chassignol.

## License

BSD 2-Clause "Simplified" License
