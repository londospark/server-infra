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
	@echo "  5. docker-hosts        - Deploy Docker host VMs (Terraform + Ansible)"
	@echo "  6. vpn-setup           - Set up WireGuard VPN on OPNsense"
	@echo ""
	@echo "Combined targets:"
	@echo "  opnsense-setup         - Build + deploy OPNsense (steps 3-4)"
	@echo "  all                    - Complete setup (steps 2-6)"
	@echo ""
	@echo "VPN Management:"
	@echo "  vpn-client NAME=laptop IP=10.0.100.10  - Create VPN client config"
	@echo ""
	@echo "Utilities:"
	@echo "  detect-storage         - Show Proxmox storage options"
	@echo "  test                   - Run all validation tests"
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

# Step 4: Deploy Docker Hosts
.PHONY: docker-hosts
docker-hosts: ## Deploy Docker host VMs with Terraform and Ansible
	@echo "Deploying Docker hosts..."
	@cd 04-docker-hosts && $(MAKE) all
	@echo ""
	@echo "=========================================="
	@echo "Docker hosts deployed!"
	@echo "=========================================="
	@echo ""
	@echo "Access your services:"
	@echo "  Grocy:       http://10.0.0.22 or http://grocy.home.lan"
	@echo "  Dev host:    http://10.0.0.21"
	@echo "  Projects:    http://10.0.0.23"
	@echo ""
	@echo "Next: Set up VPN with 'make vpn-setup'"
	@echo ""

# Step 5: Setup WireGuard VPN
.PHONY: vpn-setup
vpn-setup: ## Set up WireGuard VPN on OPNsense
	@echo "Setting up WireGuard VPN..."
	@cd 05-opnsense-wireguard && $(MAKE) setup-vpn
	@echo ""
	@echo "=========================================="
	@echo "VPN setup initiated!"
	@echo "=========================================="
	@echo ""
	@echo "Follow the instructions to complete VPN setup in OPNsense web UI"
	@echo "Create client configs with: make vpn-client NAME=laptop"
	@echo ""

.PHONY: vpn-client
vpn-client: ## Create VPN client config (usage: make vpn-client NAME=laptop IP=10.0.100.10)
	@cd 05-opnsense-wireguard && $(MAKE) client NAME=$(NAME) IP=$(IP)

# Complete setup
.PHONY: all
all: proxmox-config opnsense-setup docker-hosts vpn-setup ## Complete infrastructure setup

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
test: test-yaml test-ansible test-toml test-json test-docker test-terraform ## Run all validation tests

.PHONY: test-yaml
test-yaml: ## Validate YAML files
	@echo "Validating YAML files..."
	@pip install --quiet yamllint 2>/dev/null || true
	@yamllint --strict -d '{extends: default, rules: {line-length: {max: 200}, indentation: {spaces: 2}, document-start: disable, trailing-spaces: disable, empty-lines: disable, truthy: disable}}' .
	@echo "YAML validation passed!"

.PHONY: test-ansible
test-ansible: ## Validate Ansible playbooks
	@echo "Validating Ansible playbooks..."
	@export PROXMOX_HOST=dummy.example.com && \
	ansible-playbook --syntax-check site.yml && \
	ansible-playbook --syntax-check 01-proxmox-config/site.yml && \
	ansible-playbook --syntax-check 03-opnsense-deployment/site.yml && \
	cd 04-docker-hosts/ansible && ansible-playbook --syntax-check playbooks/bootstrap.yml && \
	cd ../../ && cd 04-docker-hosts/ansible && ansible-playbook --syntax-check playbooks/site.yml && \
	cd ../../ && cd 04-docker-hosts/ansible && ansible-playbook --syntax-check playbooks/deploy-stacks.yml && \
	cd ../../ && ansible-playbook --syntax-check 05-opnsense-wireguard/playbooks/setup-wireguard.yml
	@echo "Ansible validation passed!"

.PHONY: test-toml
test-toml: ## Validate TOML files
	@echo "Validating TOML files..."
	@python3 -m pip install --quiet toml 2>/dev/null || python -m pip install --quiet toml 2>/dev/null || true
	@python3 -c "import toml, sys, os; \
	files = [os.path.join(r, f) for r, _, fs in os.walk('.') for f in fs if f.endswith('.toml') and '.git' not in r]; \
	failed = False; \
	[print(f'✓ {f}') if not (lambda: (toml.load(open(f)), False)[1])() else (print(f'✗ {f}'), setattr(sys.modules[__name__], 'failed', True)) for f in files]; \
	sys.exit(1 if failed else 0)"
	@echo "TOML validation passed!"

.PHONY: test-json
test-json: ## Validate JSON files
	@echo "Validating JSON files..."
	@find . -name "*.json" -not -path "./.git/*" -not -path "./.terraform/*" -not -path "**/node_modules/*" -exec sh -c 'for file; do if jq empty "$$file" 2>/dev/null; then echo "✓ $$file"; else echo "✗ $$file"; exit 1; fi; done' sh {} +
	@echo "JSON validation passed!"

.PHONY: test-docker
test-docker: ## Validate docker-compose files
	@echo "Validating docker-compose files..."
	@if [ -f "00-proxmox-installer/docker-compose.yml" ]; then \
		docker compose -f 00-proxmox-installer/docker-compose.yml config --quiet && \
		echo "✓ docker-compose.yml"; \
	fi
	@echo "Docker validation passed!"

.PHONY: test-terraform
test-terraform: ## Validate Terraform configurations
	@echo "Validating Terraform configurations..."
	@cd 04-docker-hosts/terraform && \
		terraform init -backend=false > /dev/null && \
		terraform fmt -check -recursive > /dev/null && \
		terraform validate > /dev/null && \
		echo "✓ Terraform configuration valid"
	@echo "Terraform validation passed!"

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
