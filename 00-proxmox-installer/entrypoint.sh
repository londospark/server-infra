#!/bin/bash
set -e  # Exit immediately if any command fails

echo "🔨 Preparing configuration..."

# 1. Copy the answer file to a temp location to avoid modifying the original
cp /data/answer.toml /tmp/answer.toml

# 2. Inject the password from the environment variable
# We use | as a delimiter in case the password contains slashes
if [ -z "$PROXMOX_PASS" ]; then
    echo "❌ Error: PROXMOX_PASS environment variable is missing!"
    exit 1
fi

if [ -z "$PROXMOX_HOST" ]; then
    echo "❌ Error: PROXMOX_HOST is missing from .envrc!"
    exit 1
fi

if [ -z "$GATEWAY" ]; then
    echo "❌ Error: GATEWAY is missing from .envrc!"
    exit 1
fi

if [ -z "$PROXMOX_MAC" ]; then
    echo "❌ Error: PROXMOX_MAC is missing from .envrc!"
    exit 1
fi

sed -i "s|root_password = \".*\"|root_password = \"$PROXMOX_PASS\"|" /tmp/answer.toml
sed -i "s|cidr = \".*\"|cidr = \"$PROXMOX_HOST/24\"|" /tmp/answer.toml
sed -i "s|gateway = \".*\"|gateway = \"$GATEWAY\"|" /tmp/answer.toml

CLEAN_MAC=$(echo "$PROXMOX_MAC" | tr '[:upper:]' '[:lower:]' | tr -d ':')
sed -i "s|filter.ID_NET_NAME_MAC = \"{{PLACEHOLDER}}\"|filter.ID_NET_NAME_MAC = \"*${CLEAN_MAC}\"|" /tmp/answer.toml

echo "🔨 Baking answer.toml into the ISO..."

# 3. Run the Proxmox Assistant
proxmox-auto-install-assistant prepare-iso /proxmox.iso \
    --fetch-from iso \
    --answer-file /tmp/answer.toml \
    --output /data/proxmox-headless.iso

# 4. Fix Ownership (So you can actually delete/move the file on your host)
# Default to 1000:1000 if variables aren't set
TARGET_UID=${OUTPUT_UID:-1000}
TARGET_GID=${OUTPUT_GID:-1000}

chown "$TARGET_UID:$TARGET_GID" /data/proxmox-headless.iso

# 5. Cleanup artifacts
rm -f /data/auto-installer-mode.toml

echo "🎉 Success! Created: proxmox-headless.iso (Owned by user $TARGET_UID)"

