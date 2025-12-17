.PHONY: all deps iso bootstrap opnsense infra opnsense-template opnsense-vm help
.PHONY: packer-image packer-clean opnsense-cloudinit-template opnsense-cloudinit-vm
.PHONY: tf-init tf-plan tf-apply tf-destroy tf-cloudinit-init tf-cloudinit-plan tf-cloudinit-apply

TF_NET_DIR := 02-terraform/01-network-layer
TF_OPNSENSE_CI_DIR := 02-terraform/02-opnsense-cloudinit
PACKER_DIR := 03-opnsense-image

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-30s %s\n", $$1, $$2}'

deps: ## Install Ansible collections
	@echo "Installing Ansible Galaxy requirements..."
	@ansible-galaxy collection install -r requirements.yml -p ./ansible_collections --force
	@echo "Done."

iso: ## Build the Proxmox ISO
	@echo "Building ISO..."
	@cd 00-proxmox-installer && docker compose up --build

bootstrap: ## Run Post-Install Ansible
	@echo "Bootstrapping Proxmox..."
	@ansible-playbook site.yml



tf-init: ## Initialize Terraform (legacy / optional)
	@echo "Initializing Terraform in $(TF_NET_DIR)..."
	@cd $(TF_NET_DIR) && terraform init -upgrade

tf-plan: ## Plan Terraform changes (legacy / optional)
	@echo "Planning changes for $(TF_NET_DIR)..."
	@cd $(TF_NET_DIR) && terraform plan

tf-apply: ## Apply Terraform changes (legacy / optional)
	@echo "Applying Infrastructure..."
	@cd $(TF_NET_DIR) && terraform apply -auto-approve

tf-destroy: ## Destroy Terraform infrastructure (legacy / optional)
	@echo "Destroying Infrastructure..."
	@cd $(TF_NET_DIR) && terraform destroy

infra: opnsense-cloudinit-template opnsense-cloudinit-vm ## Provision Network Layer (build cloud-init template + clone via Ansible)

all: deps iso bootstrap infra ## Run Full Stack

packer-image: ## Build OPNsense cloud-init image with Packer
	@echo "Building OPNsense cloud-init image with Packer..."
	@PKR_VAR_VERSION=$${PKR_VAR_VERSION:-25.7}; \
	PKR_VAR_MIRROR=$${PKR_VAR_MIRROR:-https://mirror.init7.net/opnsense}; \
	OUTPUT_FILE="$(PACKER_DIR)/output/opnsense-$${PKR_VAR_VERSION}-proxmox.qcow2"; \
	if [ -f "$$OUTPUT_FILE" ]; then \
		echo "Image already exists: $$OUTPUT_FILE"; \
		echo "Skipping build. To rebuild, run: rm -rf $(PACKER_DIR)/output"; \
	else \
		echo "Setting default OPNsense version to $${PKR_VAR_VERSION}"; \
		echo "Setting default mirror to $${PKR_VAR_MIRROR}"; \
		cd $(PACKER_DIR) && \
		PKR_VAR_VERSION=$${PKR_VAR_VERSION} \
		PKR_VAR_MIRROR=$${PKR_VAR_MIRROR} \
		packer init . && \
		PKR_VAR_VERSION=$${PKR_VAR_VERSION} \
		PKR_VAR_MIRROR=$${PKR_VAR_MIRROR} \
		./get-iso.sh && \
		PKR_VAR_VERSION=$${PKR_VAR_VERSION} \
		packer build -force .; \
	fi

opnsense-template: packer-image ## Build and deploy OPNsense cloud-init template
	@echo "Deploying OPNsense cloud-init template to Proxmox..."
	@ansible-playbook 01-post-boot-ansible/05-opnsense-deploy-template.yml

opnsense-vm: opnsense-template ## Clone, configure, and deploy OPNsense VM
	@echo "Deploying OPNsense VM..."
	@ansible-playbook 01-post-boot-ansible/06-opnsense-clone-and-configure.yml

opnsense-deploy: opnsense-vm ## Complete OPNsense deployment (alias for opnsense-vm)

tf-cloudinit-init: ## Initialize Terraform for cloud-init OPNsense
	@echo "Initializing Terraform in $(TF_OPNSENSE_CI_DIR)..."
	@cd $(TF_OPNSENSE_CI_DIR) && terraform init -upgrade

tf-cloudinit-plan: ## Plan Terraform changes for cloud-init OPNsense
	@echo "Planning changes for $(TF_OPNSENSE_CI_DIR)..."
	@cd $(TF_OPNSENSE_CI_DIR) && terraform plan

tf-cloudinit-apply: ## Apply Terraform changes for cloud-init OPNsense
	@echo "Applying Infrastructure for cloud-init OPNsense..."
	@cd $(TF_OPNSENSE_CI_DIR) && terraform apply -auto-approve

packer-clean: ## Clean Packer build artifacts (ISO and output)
	@echo "Cleaning Packer build artifacts..."
	@rm -rf $(PACKER_DIR)/iso $(PACKER_DIR)/output $(PACKER_DIR)/packer_cache
	@echo "Cleaned: ISO files, output directory, and Packer cache"

packer-rebuild: packer-clean packer-image ## Force rebuild of OPNsense image
