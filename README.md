# Homelab Server Infrastructure

A collection of automation tools and configurations for building and managing a homelab server infrastructure with Proxmox VE. This project automates the complete setup from ISO creation to infrastructure-as-code readiness.

## Project Structure

- **[00-proxmox-installer](./00-proxmox-installer/README.md)** - Automated Proxmox VE ISO builder with pre-configured installation answers
- **[01-post-boot-ansible](./01-post-boot-ansible/README.md)** - Post-install bootstrap: SSH access, Terraform token, community repo, bridge setup, and OPNsense deployment/configuration
- **[02-terraform](./02-terraform/)** - Infrastructure as Code configurations
  - **[01-network-layer](./02-terraform/01-network-layer/)** - Legacy OPNsense VM (nano image based)
  - **[02-opnsense-cloudinit](./02-terraform/02-opnsense-cloudinit/)** - **NEW**: Cloud-init enabled OPNsense deployment
- **[03-opnsense-image](./03-opnsense-image/README.md)** - **NEW**: Packer-based OPNsense cloud-init image builder

Each folder contains its own README with detailed setup instructions.

## Platform Support

This project is designed for **macOS and Linux** systems. Windows users should use **WSL2 (Windows Subsystem for Linux)** to run this infrastructure.

## Dependencies

### Global Requirements

- **Docker** (version 20.10+) - Container runtime
- **Docker Compose** (version 2.0+) - Multi-container orchestration
  - Installation: [Install Docker Desktop](https://www.docker.com/products/docker-desktop) or [install separately](https://docs.docker.com/compose/install/)
- **Ansible** (version 2.9+) - Infrastructure automation
  - Required collections: `community.general`, `ansible.posix` (installed via `make deps`)
- **direnv** - Environment variable management
- **Packer** (version 1.8+) - For building OPNsense cloud-init images
  - Installation: [Install Packer](https://developer.hashicorp.com/packer/downloads)
- **QEMU** - For Packer builds (required on build machine)
  - macOS: `brew install qemu`
  - Ubuntu/Debian: `apt-get install qemu-system qemu-utils`

### Optional Tools

- **Git** - Version control (for cloning and managing this repository)
- **Terraform** (version 1.0+) - For infrastructure as code (if using Terraform deployment)
- **USB Flashing Tools** (for OS deployment):
  - **Balena Etcher** - Cross-platform GUI tool (recommended)
  - Platform-native tools: `dd` (Linux), `diskutil` (macOS)
- **Bitwarden CLI** (`bw`) - For password management integration (future enhancement)

## Quick Start

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd <path-to-cloned-repo>
   ```
   > Replace `<path-to-cloned-repo>` with the name of the directory you cloned into (e.g., `server-infra`)

2. **Install direnv** (if not already installed):
   
   **macOS**:
   ```bash
   brew install direnv
   ```
   
   **Ubuntu/Debian**:
   ```bash
   sudo apt-get install direnv
   ```
   
   **Fedora**:
   ```bash
   sudo dnf install direnv
   ```
   
   **Arch Linux**:
   ```bash
   sudo pacman -S direnv
   ```

3. **Configure direnv for your shell**:
   
   > **Important**: After installing direnv, you must add a hook to your shell configuration for direnv to work automatically.
   
   **For bash** (`~/.bashrc`):
   ```bash
   eval "$(direnv hook bash)"
   ```
   
   **For zsh** (`~/.zshrc`):
   ```bash
   eval "$(direnv hook zsh)"
   ```
   
   **For fish** (`~/.config/fish/config.fish`):
   ```bash
   direnv hook fish | source
   ```
   
   After adding the hook, reload your shell:
   ```bash
   exec $SHELL
   ```

4. **Prepare environment variables** (required before anything else):
   - Copy the `.envrc.example` file to `.envrc`:
     ```bash
     cp .envrc.example .envrc
     ```
   - Edit `.envrc` and fill in the placeholder values:
     - `PROXMOX_HOST` - IP address of your Proxmox host
     - `PROXMOX_PASS` - Initial root password for Proxmox
     - `PROXMOX_MAC` - MAC address of the Proxmox host
     - `GATEWAY` - Gateway IP address
     - `OPNSENSE_*` - (optional) defaults for post-boot LAN reconfig: source IP, SSH creds, and target LAN network

5. **Generate SSH keys** (if you don't already have them):
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
   ```
   This is required for the Ansible bootstrap phase and OPNsense cloud-init deployment.

6. **Enable direnv** to load environment variables:
   ```bash
   direnv allow
   ```
   This loads the environment variables from `.envrc`, which are required for all subsequent operations.

7. **Use the Makefile for convenient commands**:
   ```bash
   make help          # Show all available commands
   make deps          # Install Ansible collections and dependencies
   make iso           # Build the Proxmox ISO (Stage 0)
   make bootstrap     # Run post-boot Ansible (user/role/token, repo swap)
   make opnsense      # Reconfigure OPNsense LAN IP post-boot (default 192.168.1.1 -> 10.x.x.x)
   make tf-init       # (Optional) init Terraform provider
   make tf-plan       # (Optional) plan Terraform-defined OPNsense VM
   make tf-apply      # (Optional) apply Terraform-defined OPNsense VM
    make all           # Full stack: deps + iso + bootstrap + infra + opnsense
   ```

8. Or navigate to the subfolder for what you want to set up:
   ```bash
   cd 00-proxmox-installer
   ```
   and follow the README in that subfolder for detailed instructions.

## System Requirements

- **Supported OS**: macOS or Linux (including WSL2 on Windows)
- **Minimum**: 8GB RAM, 20GB free disk space for builds
- **Recommended**: 16GB+ RAM, 50GB+ free disk space
- **Internet**: Required for downloading ISOs and packages

### Windows Users

If you're on Windows, install and use **WSL2 (Windows Subsystem for Linux)**:

1. [Install WSL2](https://learn.microsoft.com/en-us/windows/wsl/install)
2. Choose a Linux distribution (Ubuntu 22.04 LTS recommended)
3. Clone this repository inside your WSL2 environment
4. Follow the Quick Start guide above within your WSL2 terminal
5. For flashing the ISO to USB, you can use Balena Etcher on Windows while keeping your build tools in WSL2
   - The generated ISO file can be accessed from Windows via: `\\wsl$\<distro-name>\home\<username>\<path-to-cloned-repo>\00-proxmox-installer\proxmox-headless.iso`

## OPNsense Deployment Options

This project now supports **two methods** for deploying OPNsense:

### Method 1: Cloud-Init Image (Recommended - NEW!)

**Advantages:**
- ✅ Fully automated with cloud-init
- ✅ SSH keys injected automatically
- ✅ Network configured via cloud-init metadata
- ✅ Admin user created automatically
- ✅ No manual post-deployment configuration needed
- ✅ Industry-standard cloud-init workflow
- ✅ Works with Ansible and Terraform

**Workflow:**
```bash
# 1. Build cloud-init enabled image with Packer
make opnsense-cloudinit-template

# 2. Deploy VM from template
make opnsense-cloudinit-vm

# 3. Set admin password for web UI
make opnsense-set-password

# 4. Configure routing (for single-NIC Proxmox homelab)
make opnsense-routing
```

**Access:**
- SSH: `ssh -J root@<proxmox-ip> root@<lan-ip>` (using your SSH key)
- Web UI: `https://<lan-ip>` (username/password from step 3)

**Note on Single-NIC Homelab Setup:**
- If your Proxmox host has only one physical NIC, you'll need a static route on your home router
- Route: `10.0.0.0/24` via `<proxmox-ip>` (e.g., `10.0.0.0/24` via `192.168.1.2`)
- This allows your devices to access VMs behind OPNsense (10.0.0.x network)
- Alternatively, add the route on each client machine that needs access

**See:** [03-opnsense-image/README.md](./03-opnsense-image/README.md)

### Method 2: Nano Image (Legacy)

**Workflow:**
```bash
# 1. Download nano image and create template
make opnsense-template

# 2. Clone VM from template
make opnsense-vm

# 3. Manually reconfigure LAN IP
make opnsense
```

**Limitations:**
- ⚠️ No cloud-init support
- ⚠️ Manual SSH key setup required
- ⚠️ Post-deployment LAN reconfiguration needed
- ⚠️ Smaller image size (~500MB vs ~1.4GB)

## Current Flow

### Recommended Flow (Cloud-Init)

1. **Build ISO**: `make iso` (optional if you already have Proxmox installed)
2. **Bootstrap host**: `make bootstrap` (SSH key, Terraform API token, community repo, bridges)
3. **Build OPNsense image and template**: `make opnsense-cloudinit-template` (downloads OPNsense ISO, builds with Packer, uploads to Proxmox)
4. **Deploy VM**: `make opnsense-cloudinit-vm` (clones template with cloud-init configuration)
5. **Set admin password**: `make opnsense-set-password` (creates web UI admin user)
6. **Configure routing**: `make opnsense-routing` (enables access to VMs from home network)
7. **Access OPNsense**: SSH and web UI are immediately available

### Legacy Flow (Nano Image)

1. **Build ISO**: `make iso`
2. **Bootstrap host**: `make bootstrap`
3. **Prepare template**: `make opnsense-template` (downloads nano image)
4. **Clone VM**: `make opnsense-vm` (Ansible full clone)
5. **Reconfigure LAN**: `make opnsense` (manual post-boot step)
6. **Terraform (optional)**: `make tf-init && make tf-plan`



## Work Completed

This project implements a complete Proxmox VE infrastructure automation pipeline:

1. **ISO Automation** - Docker-based ISO builder downloads latest Proxmox VE, embeds pre-configured answers (`answer.toml`), and produces a headless-ready installation image
2. **Ansible Bootstrap & Network** - Post-boot playbooks that:
   - Install SSH public key for key-based authentication
   - Create Terraform role/user/token and switch to community repository
   - Configure vmbr0/vmbr1 bridges
   - Deploy OPNsense templates and VMs
   - Create admin users for OPNsense web UI
   - Configure routing for single-NIC homelab setups
3. **OPNsense Cloud-Init Images** - **NEW**: Packer-based workflow to build production-ready OPNsense images with:
   - Cloud-init support for automated deployment
   - QEMU Guest Agent integration
   - SSH key injection via cloud-init
   - Automated network configuration (WAN DHCP or static, LAN static)
   - First-boot script for initial setup
4. **Terraform IaC** - Multiple deployment options:
   - Legacy nano image-based deployment
   - **NEW**: Cloud-init enabled deployment with full automation
5. **Environment Management** - direnv integration for secure credential and variable management
6. **Cross-Platform Support** - Works on macOS, Linux, and Windows (via WSL2)

## Known Gotchas & Important Notes

### direnv Must Be Allowed First
- `.envrc` must be processed with `direnv allow` before running any builds or playbooks
- Docker Compose depends on `UID` and `GID` variables from `.envrc` - builds will fail silently without them
- Environment variables are not inherited by child shells if direnv is not hooked into your shell

### Proxmox Installation Answers
- The `answer.toml` in `00-proxmox-installer` uses static network configuration (`source = "from-answer"`)
- Network settings (`cidr`, `gateway`, `filter.ID_NET_NAME_MAC`) are placeholders and must be filled in `.envrc` before building
- Root password placeholder in `answer.toml` is replaced by `PROXMOX_PASS` environment variable
- ZFS RAID configuration in `answer.toml` requires multiple disks; adjust `disk_list` and `zfs.raid` for your hardware

### Ansible Bootstrap Notes
- Initial SSH connection uses password authentication (requires `PROXMOX_PASS` and `PROXMOX_HOST`)
- SSH key generation (`ssh-keygen`) must complete before running the playbook
- API token is automatically appended to `.envrc` - you must run `direnv allow` again after the playbook completes
- The playbook modifies `.envrc` directly; back it up if you have custom additions

### USB Flashing
- Ensure USB stick is at least 8GB
- On Linux with `dd`, use the device (`/dev/sdX`), not the partition (`/dev/sdX1`)
- macOS users should use `rdiskX` for `dd` (faster) instead of `diskX`
- Windows users building in WSL2 can access the ISO via UNC path: `\\wsl$\<distro>\home\<user>\path\to\proxmox-headless.iso`

### Repository Transitions
- Proxmox defaults to enterprise repository (requires valid subscription)
- The Ansible playbook includes `02-remove-enterprise.yml` to switch to community repo automatically
- If you have a subscription, you can skip this step or customize the playbook

## License

MIT License - See LICENSE file for details.
