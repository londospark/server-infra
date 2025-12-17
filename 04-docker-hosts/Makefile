.PHONY: help init plan apply destroy configure deploy all clean

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(GREEN)Docker Hosts Management$(NC)"
	@echo ""
	@echo "$(BLUE)Terraform Commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

init: ## Initialize Terraform
	cd terraform && terraform init

plan: ## Plan infrastructure changes
	cd terraform && terraform plan

apply: ## Create/update infrastructure
	@echo "$(GREEN)Creating VMs...$(NC)"
	cd terraform && terraform apply -auto-approve
	@echo "$(YELLOW)Waiting 60 seconds for cloud-init to complete...$(NC)"
	@sleep 60
	@echo "$(GREEN)Generating Ansible inventory...$(NC)"
	cd terraform && terraform output ansible_inventory > ../ansible/inventory/hosts.yml
	@echo "$(GREEN)Infrastructure ready!$(NC)"
	@echo "$(YELLOW)Next: make configure$(NC)"

destroy: ## Destroy all infrastructure
	cd terraform && terraform destroy

configure: ## Configure VMs with Ansible
	@echo "$(GREEN)Bootstrapping VMs...$(NC)"
	cd ansible && ansible-playbook -i inventory/hosts.yml playbooks/bootstrap.yml
	@echo "$(GREEN)Configuring Docker and services...$(NC)"
	cd ansible && ansible-playbook -i inventory/hosts.yml playbooks/site.yml
	@echo "$(GREEN)Configuration complete!$(NC)"

deploy: ## Deploy application stacks
	@echo "$(GREEN)Deploying application stacks...$(NC)"
	cd ansible && ansible-playbook -i inventory/hosts.yml playbooks/deploy-stacks.yml
	@echo "$(GREEN)Deployment complete!$(NC)"

deploy-dev: ## Deploy dev-host stack only
	cd ansible && ansible-playbook -i inventory/hosts.yml playbooks/deploy-stacks.yml --tags dev

deploy-home: ## Deploy home-host stack only
	cd ansible && ansible-playbook -i inventory/hosts.yml playbooks/deploy-stacks.yml --tags home

deploy-projects: ## Deploy projects-host stack only
	cd ansible && ansible-playbook -i inventory/hosts.yml playbooks/deploy-stacks.yml --tags projects

all: apply configure deploy ## Complete setup (terraform + ansible + deploy)

test: ## Test Ansible connectivity
	cd ansible && ansible -i inventory/hosts.yml all -m ping

status: ## Show VM status
	cd terraform && terraform output docker_hosts

clean: ## Clean Terraform state
	cd terraform && rm -rf .terraform terraform.tfstate* .terraform.lock.hcl

ssh-dev: ## SSH to dev-host
	ssh -i ~/.ssh/ansible_homelab ansible@10.0.0.21

ssh-home: ## SSH to home-host
	ssh -i ~/.ssh/ansible_homelab ansible@10.0.0.22

ssh-projects: ## SSH to projects-host
	ssh -i ~/.ssh/ansible_homelab ansible@10.0.0.23
