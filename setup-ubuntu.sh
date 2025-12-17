#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Server Infrastructure Setup for Ubuntu${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${YELLOW}Updating system...${NC}"
sudo apt update
echo ""

# Core dependencies
echo -e "${YELLOW}Installing core dependencies...${NC}"
sudo apt install -y git make curl wget software-properties-common
echo -e "${GREEN}✓${NC} Core dependencies installed"
echo ""

# Python and pip
echo -e "${YELLOW}Installing Python and pip...${NC}"
sudo apt install -y python3 python3-pip python3-venv
echo -e "${GREEN}✓${NC} Python and pip installed"
echo ""

# Ansible
echo -e "${YELLOW}Installing Ansible...${NC}"
sudo apt install -y ansible
echo -e "${GREEN}✓${NC} Ansible installed"
echo ""

# Packer for OPNsense image building
echo -e "${YELLOW}Installing Packer...${NC}"
if ! command_exists packer; then
    # Add HashiCorp GPG key
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    # Add HashiCorp repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update
    sudo apt install -y packer
    echo -e "${GREEN}✓${NC} Packer installed"
else
    echo -e "${GREEN}✓${NC} Packer is already installed"
fi
echo ""

# Docker and Docker Compose for Proxmox installer
echo -e "${YELLOW}Installing Docker and Docker Compose...${NC}"
if ! command_exists docker; then
    # Install Docker
    sudo apt install -y ca-certificates gnupg lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo -e "${GREEN}✓${NC} Docker installed"
else
    echo -e "${GREEN}✓${NC} Docker is already installed"
fi

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
sudo apt install -y yamllint jq
echo -e "${GREEN}✓${NC} Validation tools installed"
echo ""

# Python packages for validation
echo -e "${YELLOW}Installing Python packages...${NC}"
pip3 install --user toml
echo -e "${GREEN}✓${NC} Python toml package installed"
echo ""

# Optional: direnv for .envrc support
echo -e "${YELLOW}Installing direnv (optional, for .envrc support)...${NC}"
sudo apt install -y direnv
echo -e "${GREEN}✓${NC} direnv installed"
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
verify_command "python3" "Python"
verify_command "pip3" "Pip"
verify_command "ansible" "Ansible"
verify_command "packer" "Packer"
verify_command "docker" "Docker"
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
