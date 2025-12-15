# Homelab Server Infrastructure

A collection of automation tools and configurations for building and managing a homelab server infrastructure. Each subfolder contains its own README with detailed setup instructions.

## Project Structure

- **00-proxmox-installer**: Automated Proxmox VE ISO builder with pre-configured installation answers

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

7. Navigate to the subfolder for what you want to set up:
   ```bash
   cd 00-proxmox-installer
   ```

8. Follow the README in that subfolder for detailed instructions.

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

## License

MIT License - See LICENSE file for details.
