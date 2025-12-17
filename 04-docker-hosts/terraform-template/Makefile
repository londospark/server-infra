.PHONY: help create-template destroy-template

help:
	@echo "Fedora Template Management"
	@echo ""
	@echo "  create-template   - Create Fedora 41 cloud template"
	@echo "  destroy-template  - Remove template"
	@echo ""

create-template:
	@echo "Creating Fedora 41 cloud template..."
	terraform init
	terraform apply -auto-approve
	@echo ""
	@echo "✓ Template created! (VM ID: 9041)"

destroy-template:
	terraform destroy -auto-approve
