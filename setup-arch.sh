#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Server Infrastructure Setup for Arch Linux${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install packages
install_package() {
    local package=$1
    local installer=${2:-pacman}
    
    if $installer -Qi "$package" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $package is already installed"
    else
        echo -e "${YELLOW}Installing $package...${NC}"
        if [ "$installer" = "yay" ]; then
            yay -S --noconfirm "$package"
        else
            sudo pacman -S --noconfirm "$package"
        fi
        echo -e "${GREEN}✓${NC} $package installed"
    fi
}

# Check for yay
if ! command_exists yay; then
    echo -e "${RED}Error: yay is not installed. Please install yay first.${NC}"
    echo "You can install it from AUR: https://github.com/Jguer/yay"
    exit 1
fi

echo -e "${YELLOW}Updating system...${NC}"
sudo pacman -Syu --noconfirm
echo ""

# Core dependencies
echo -e "${YELLOW}Installing core dependencies...${NC}"
install_package "git"
install_package "make"
install_package "curl"
install_package "wget"
echo ""

# Python and pip
echo -e "${YELLOW}Installing Python and pip...${NC}"
install_package "python"
install_package "python-pip"
echo ""

# Ansible
echo -e "${YELLOW}Installing Ansible...${NC}"
install_package "ansible"
echo ""

# Packer for OPNsense image building
echo -e "${YELLOW}Installing Packer...${NC}"
install_package "packer"
echo ""

# Terraform for Docker hosts infrastructure
echo -e "${YELLOW}Installing Terraform...${NC}"
install_package "terraform"
echo ""

# Docker and Docker Compose for Proxmox installer
echo -e "${YELLOW}Installing Docker and Docker Compose...${NC}"
install_package "docker"
install_package "docker-compose"

# Enable and start Docker service
if ! systemctl is-active --quiet docker; then
    echo -e "${YELLOW}Enabling and starting Docker service...${NC}"
    sudo systemctl enable docker
    sudo systemctl start docker
    echo -e "${GREEN}✓${NC} Docker service started"
fi

# Add current user to docker group
if ! groups | grep -q docker; then
    echo -e "${YELLOW}Adding current user to docker group...${NC}"
    sudo usermod -aG docker "$USER"
    echo -e "${YELLOW}Note: You need to log out and back in for docker group changes to take effect${NC}"
fi
echo ""

# Validation tools
echo -e "${YELLOW}Installing validation tools...${NC}"
install_package "yamllint"
install_package "jq"
echo ""

# Python packages for validation
echo -e "${YELLOW}Installing Python packages...${NC}"
pip install --user --break-system-packages toml
echo -e "${GREEN}✓${NC} Python toml package installed"
echo ""

# Optional: direnv for .envrc support
echo -e "${YELLOW}Installing direnv (optional, for .envrc support)...${NC}"
install_package "direnv"
echo -e "${YELLOW}Note: Add 'eval \"\$(direnv hook bash)\"' to your ~/.bashrc or shell config${NC}"
echo ""

# Install Ansible collections
echo -e "${YELLOW}Installing Ansible collections...${NC}"
ansible-galaxy install -r requirements.yml
echo -e "${GREEN}✓${NC} Ansible collections installed"
echo ""

# Verify installations
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Verifying installations...${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

verify_command() {
    local cmd=$1
    local name=${2:-$cmd}
    if command_exists "$cmd"; then
        local version=$($cmd --version 2>&1 | head -n1)
        echo -e "${GREEN}✓${NC} $name: $version"
    else
        echo -e "${RED}✗${NC} $name: not found"
    fi
}

verify_command "git" "Git"
verify_command "make" "Make"
verify_command "python" "Python"
verify_command "pip" "Pip"
verify_command "ansible" "Ansible"
verify_command "packer" "Packer"
verify_command "terraform" "Terraform"
verify_command "docker" "Docker"
verify_command "docker-compose" "Docker Compose"
verify_command "yamllint" "yamllint"
verify_command "jq" "jq"
verify_command "direnv" "direnv"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Copy .envrc.example to .envrc and configure your environment variables"
echo "2. Run 'direnv allow' if using direnv"
echo "3. Run 'make test' to validate your setup"
echo "4. Run 'make help' to see available commands"
echo ""
echo -e "${YELLOW}Note: If you were added to the docker group, please log out and back in${NC}"
