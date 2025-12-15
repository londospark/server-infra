.PHONY: all deps iso bootstrap opnsense infra tf-init tf-plan tf-apply tf-destroy help

TF_NET_DIR := 02-terraform/01-network-layer

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

opnsense: ## Deploy OPNsense router VM
	@echo "Deploying OPNsense..."
	@ansible-playbook 01-post-boot-ansible/05-deploy-opnsense.yml

tf-init: ## Initialize Terraform
	@echo "Initializing Terraform in $(TF_NET_DIR)..."
	@cd $(TF_NET_DIR) && terraform init -upgrade

tf-plan: ## Plan Terraform changes
	@echo "Planning changes for $(TF_NET_DIR)..."
	@cd $(TF_NET_DIR) && terraform plan

tf-apply: ## Apply Terraform changes
	@echo "Applying Infrastructure..."
	@cd $(TF_NET_DIR) && terraform apply -auto-approve

tf-destroy: ## Destroy Terraform infrastructure
	@echo "Destroying Infrastructure..."
	@cd $(TF_NET_DIR) && terraform destroy

infra: tf-init tf-apply ## Provision Network Layer

all: deps iso bootstrap opnsense infra ## Run Full Stack
