.PHONY: help
help: ## Show this help message
	@echo "Server Infrastructure Setup"
	@echo ""
	@echo "Available targets:"
	@echo "  install-proxmox    - Create Proxmox installer USB"
	@echo "  proxmox-setup      - Configure Proxmox post-installation"
	@echo "  opnsense-setup     - Build and deploy OPNsense firewall (full setup)"
	@echo ""
	@echo "Individual OPNsense steps:"
	@echo "  opnsense-image     - Build OPNsense cloud-init image with Packer"
	@echo "  opnsense-deploy    - Deploy OPNsense template and VM to Proxmox"
	@echo ""
	@echo "Utilities:"
	@echo "  clean              - Clean build artifacts"

# 00: Proxmox Installer
.PHONY: install-proxmox
install-proxmox: ## Create Proxmox installer USB
	@echo "Creating Proxmox installer USB..."
	cd 00-proxmox-installer && $(MAKE) create-usb

# Ansible dependencies
.PHONY: ansible-deps
ansible-deps: ## Install Ansible dependencies
	@echo "Installing Ansible dependencies..."
	ansible-galaxy install -r requirements.yml

# 01: Post-boot Ansible Setup
.PHONY: proxmox-setup
proxmox-setup: ansible-deps ## Configure Proxmox post-installation
	@echo "Running Proxmox setup playbooks..."
	ansible-playbook -i inventory 01-post-boot-ansible/site.yml

# 02: OPNsense Image Building
.PHONY: opnsense-image
opnsense-image: ## Build OPNsense cloud-init image with Packer
	@echo "Building OPNsense cloud-init image with Packer..."
	@PKR_VAR_VERSION=$${PKR_VAR_VERSION:-25.7}; \
	PKR_VAR_MIRROR=$${PKR_VAR_MIRROR:-https://mirror.init7.net/opnsense}; \
	OUTPUT_FILE="02-opnsense-image/output/opnsense-$${PKR_VAR_VERSION}-proxmox.qcow2"; \
	if [ -f "$$OUTPUT_FILE" ]; then \
		echo "Image already exists: $$OUTPUT_FILE"; \
		echo "Skipping build. To rebuild, run: make clean"; \
	else \
		cd 02-opnsense-image && \
		PKR_VAR_VERSION=$${PKR_VAR_VERSION} \
		PKR_VAR_MIRROR=$${PKR_VAR_MIRROR} \
		packer init . && \
		PKR_VAR_VERSION=$${PKR_VAR_VERSION} \
		PKR_VAR_MIRROR=$${PKR_VAR_MIRROR} \
		./get-iso.sh && \
		PKR_VAR_VERSION=$${PKR_VAR_VERSION} \
		packer build -force .; \
	fi

# 03: OPNsense Deployment
.PHONY: opnsense-deploy
opnsense-deploy: ansible-deps ## Deploy OPNsense to Proxmox
	@echo "Deploying OPNsense to Proxmox..."
	ansible-playbook -i inventory 03-opnsense-deployment/site.yml

# Complete OPNsense setup
.PHONY: opnsense-setup
opnsense-setup: opnsense-image opnsense-deploy ## Complete OPNsense setup (image + deploy)
	@echo ""
	@echo "=========================================="
	@echo "OPNsense setup complete!"
	@echo "=========================================="
	@echo ""
	@echo "Access OPNsense WebUI at: https://10.0.0.1"
	@echo "Username: admin"
	@echo "Password: Set via OPNSENSE_ADMIN_PASSWORD environment variable"
	@echo ""
	@echo "Note: Add static route on your home router:"
	@echo "  Network: 10.0.0.0/24"
	@echo "  Gateway: 192.168.1.2 (Proxmox host)"
	@echo ""

.PHONY: clean
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	rm -rf 02-opnsense-image/iso
	rm -rf 02-opnsense-image/output
	rm -rf 02-opnsense-image/packer_cache
	@echo "Cleaned: ISO files, output directory, and Packer cache"
