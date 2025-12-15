# Homelab Server Infrastructure

A collection of automation tools and configurations for building and managing a homelab server infrastructure. Each subfolder contains its own README with detailed setup instructions.

## Project Structure

- **00-proxmox-installer**: Automated Proxmox VE ISO builder with pre-configured installation answers

## Dependencies

### Global Requirements

- **Docker** (version 20.10+) - Container runtime
- **Docker Compose** (version 2.0+) - Multi-container orchestration
  - Installation: [Install Docker Desktop](https://www.docker.com/products/docker-desktop) or [install separately](https://docs.docker.com/compose/install/)

### Optional Tools

- **Git** - Version control (for cloning and managing this repository)
- **USB Flashing Tools** (for OS deployment):
  - **Balena Etcher** - Cross-platform GUI tool (recommended)
  - **Rufus** - Windows command-line tool
  - Platform-native tools: `dd` (Linux/macOS), `diskutil` (macOS)

## Quick Start

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd server-infra
   ```

2. Navigate to the subfolder for what you want to set up:
   ```bash
   cd 00-proxmox-installer
   ```

3. Follow the README in that subfolder for detailed instructions.

## System Requirements

- **Minimum**: 8GB RAM, 20GB free disk space for builds
- **Recommended**: 16GB+ RAM, 50GB+ free disk space
- **Internet**: Required for downloading ISOs and packages

## License

MIT License - See LICENSE file for details.
