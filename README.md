# Homelab Server Infrastructure

A collection of automation tools and configurations for building and managing a homelab server infrastructure with Proxmox VE. This project automates the complete setup from ISO creation to infrastructure-as-code readiness.

## Project Structure

- **[00-proxmox-installer](./00-proxmox-installer/README.md)** - Automated Proxmox VE ISO builder with pre-configured installation answers
- **[01-post-boot-ansible](./01-post-boot-ansible/README.md)** - Post-install bootstrap: SSH access, Terraform token, community repo, bridge setup, and OPNsense deployment (nano image, no installer)
- **[02-terraform](./02-terraform/01-network-layer)** - Proxmox provider wiring; currently describes the OPNsense VM (two virtio NICs, vmbr0/vmbr1) and uses ISO-based install if you choose to apply it

Each folder contains its own README with detailed setup instructions.

## Platform Support

This project is designed for **macOS and Linux** systems. Windows users should use **WSL2 (Windows Subsystem for Linux)** to run this infrastructure.

## Dependencies

### Global Requirements

- **Docker** (version 20.10+) - Container runtime
- **Docker Compose** (version 2.0+) - Multi-container orchestration
  - Installation: [Install Docker Desktop](https://www.docker.com/products/docker-desktop) or [install separately](https://docs.docker.com/compose/install/)
- **Ansible** (version 2.9+) - Infrastructure automation
- **direnv** - Environment variable management

### Optional Tools

- **Git** - Version control (for cloning and managing this repository)
- **USB Flashing Tools** (for OS deployment):
  - **Balena Etcher** - Cross-platform GUI tool (recommended)
  - Platform-native tools: `dd` (Linux), `diskutil` (macOS)

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

5. **Generate SSH keys** (if you don't already have them):
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
   ```
   This is required for the Ansible bootstrap phase.

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
   make opnsense      # Deploy OPNsense from nano image (no installer)
   make tf-init       # (Optional) init Terraform provider
   make tf-plan       # (Optional) plan Terraform-defined OPNsense VM
   make tf-apply      # (Optional) apply Terraform-defined OPNsense VM
   make all           # Full stack: deps + iso + bootstrap + opnsense + infra
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

## Current Flow

1. **Build ISO**: `make iso` (optional if you already have Proxmox installed)
2. **Bootstrap host**: `make bootstrap` (SSH key, Terraform API token, community repo, bridges vmbr0/vmbr1)
3. **Deploy OPNsense**: `make opnsense` (downloads latest nano image, imports as disk, brings up VM on vmbr0/vmbr1; default LAN 192.168.1.1)
4. **Terraform (optional)**: `make tf-init && make tf-plan` (describes the OPNsense VM via proxmox provider; use if you want IaC management of the VM)
5. **All-in-one**: `make all` runs deps + iso + bootstrap + opnsense + infra (terraform apply)

### What Terraform Does (today)
- Configures the Proxmox provider and defines an `opnsense` VM with two virtio NICs (WAN: vmbr0, LAN: vmbr1) and ISO-based install variables.
- Use it if you prefer the VM to be managed declaratively via Terraform. If you stick with the Ansible nano-image deployment, Terraform is optional—just avoid applying the conflicting VM resource.

## Work Completed

This project implements a complete Proxmox VE infrastructure automation pipeline:

1. **ISO Automation** - Docker-based ISO builder downloads latest Proxmox VE, embeds pre-configured answers (`answer.toml`), and produces a headless-ready installation image
2. **Ansible Bootstrap & Network** - Post-boot playbooks that:
   - Install SSH public key for key-based authentication
   - Create Terraform role/user/token and switch to community repository
   - Configure vmbr0/vmbr1 bridges
   - Deploy OPNsense from the official nano image (no installer)
3. **Terraform (Optional)** - Proxmox provider configuration describing the OPNsense VM (ISO-based approach) for those who want declarative management
4. **Environment Management** - direnv integration for secure credential and variable management
5. **Cross-Platform Support** - Works on macOS, Linux, and Windows (via WSL2)

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
