.PHONY: help setup-vpn client clean

help: ## Show this help
	@echo "WireGuard VPN Management"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

setup-vpn: ## Set up WireGuard server on OPNsense
	ansible-playbook -i ../inventory playbooks/setup-wireguard.yml

client: ## Generate client config (usage: make client NAME=laptop IP=10.0.100.10)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make client NAME=laptop IP=10.0.100.10"; \
		exit 1; \
	fi
	@export WG_CLIENT_NAME=$(NAME); \
	export WG_CLIENT_IP=$(or $(IP),10.0.100.10); \
	ansible-playbook -i ../inventory playbooks/setup-wireguard.yml --tags client

qr: ## Generate QR code for client config (usage: make qr NAME=laptop)
	@if [ ! -f wireguard-$(NAME).conf ]; then \
		echo "Error: Config file wireguard-$(NAME).conf not found"; \
		exit 1; \
	fi
	@which qrencode > /dev/null || (echo "Installing qrencode..." && sudo dnf install -y qrencode)
	qrencode -t ansiutf8 < wireguard-$(NAME).conf

clean: ## Remove generated keys and configs
	rm -f wireguard-*.conf wireguard-server-keys.txt
