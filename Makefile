.PHONY: help
help: ## Show this help message
	@echo "Server Infrastructure Setup"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Setup steps (run in order):"
	@echo "  1. install-proxmox     - Create Proxmox installer USB"
	@echo "  2. proxmox-config      - Bootstrap Proxmox (SSH keys, storage)"
	@echo "  3. opnsense-build      - Build OPNsense cloud-init image"
	@echo "  4. opnsense-deploy     - Deploy OPNsense VM to Proxmox"
	@echo ""
	@echo "Combined targets:"
	@echo "  opnsense-setup         - Build + deploy OPNsense (steps 3-4)"
	@echo "  all                    - Complete setup (steps 2-4)"
	@echo ""
	@echo "Utilities:"
	@echo "  detect-storage         - Show Proxmox storage options"
	@echo "  clean                  - Remove build artifacts"
	@echo ""

# Install Ansible dependencies
.PHONY: ansible-deps
ansible-deps:
	@ansible-galaxy install -r requirements.yml

# Step 0: Create Proxmox Installer USB
.PHONY: install-proxmox
install-proxmox: ## Create Proxmox installer USB
	@echo "Creating Proxmox installer USB..."
	@cd 00-proxmox-installer && $(MAKE) create-usb

# Step 1: Bootstrap Proxmox
.PHONY: proxmox-config
proxmox-config: ansible-deps ## Bootstrap Proxmox (SSH keys, storage detection)
	@echo "Configuring Proxmox..."
	@ansible-playbook -i inventory 01-proxmox-config/site.yml

# Step 2: Build OPNsense Image
.PHONY: opnsense-build
opnsense-build: ## Build OPNsense cloud-init image with Packer
	@echo "Building OPNsense cloud-init image..."
	@cd 02-opnsense-image && \
	PKR_VAR_VERSION=$${PKR_VAR_VERSION:-25.7} \
	PKR_VAR_MIRROR=$${PKR_VAR_MIRROR:-https://mirror.init7.net/opnsense} \
	./get-iso.sh && \
	packer init . && \
	packer build -force .

# Step 3: Deploy OPNsense
.PHONY: opnsense-deploy
opnsense-deploy: ansible-deps ## Deploy OPNsense template and VM to Proxmox
	@echo "Deploying OPNsense to Proxmox..."
	@ansible-playbook -i inventory 03-opnsense-deployment/site.yml

# Combined: Build and deploy OPNsense
.PHONY: opnsense-setup
opnsense-setup: opnsense-build opnsense-deploy ## Build and deploy OPNsense firewall
	@echo ""
	@echo "=========================================="
	@echo "OPNsense setup complete!"
	@echo "=========================================="
	@echo ""
	@echo "Access OPNsense WebUI at: https://10.0.0.1"
	@echo "  Username: admin"
	@echo "  Password: $$OPNSENSE_ADMIN_PASSWORD"
	@echo ""
	@echo "Add static route on your home router:"
	@echo "  Network: 10.0.0.0/24"
	@echo "  Gateway: <Proxmox IP>"
	@echo ""

# Complete setup
.PHONY: all
all: proxmox-config opnsense-setup ## Complete infrastructure setup

# Utilities
.PHONY: detect-storage
detect-storage: ansible-deps ## Show available Proxmox storage
	@ansible-playbook -i inventory 01-proxmox-config/02-detect-storage.yml

.PHONY: clean
clean: ## Remove build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf 02-opnsense-image/iso
	@rm -rf 02-opnsense-image/output
	@rm -rf 02-opnsense-image/packer_cache
	@echo "Clean complete"

# Testing and Validation
.PHONY: test
test: test-ansible test-packer ## Run all tests

.PHONY: test-ansible
test-ansible: ## Validate Ansible playbooks
	@echo "Validating Ansible playbooks..."
	@ansible-playbook --syntax-check 01-proxmox-config/site.yml
	@ansible-playbook --syntax-check 03-opnsense-deployment/site.yml
	@echo "Running ansible-lint..."
	@ansible-lint 01-proxmox-config/
	@ansible-lint 03-opnsense-deployment/
	@echo "Ansible validation passed!"

.PHONY: test-packer
test-packer: ## Validate Packer templates
	@echo "Validating Packer template..."
	@cd 02-opnsense-image && packer init . && packer fmt -check .
	@echo "Packer validation passed!"

.PHONY: check
check: ## Quick syntax check (no linting)
	@echo "Running syntax checks..."
	@ansible-playbook --syntax-check 01-proxmox-config/site.yml
	@ansible-playbook --syntax-check 03-opnsense-deployment/site.yml
	@cd 02-opnsense-image && packer init . && packer fmt -check .
	@echo "Syntax checks passed!"
