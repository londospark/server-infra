FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install prerequisites
# We need curl to scrape the website and wget to download.
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup Proxmox Repository
# Note: We stick to the 'bookworm' repo to get the stable 'auto-install-assistant' tool.
# This tool generally works for modifying any recent Proxmox ISO (8.x or 9.x).
RUN wget -q https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg \
    && echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list

# 3. Install the Assistant Tool
RUN apt-get update && apt-get install -y \
    proxmox-auto-install-assistant \
    && rm -rf /var/lib/apt/lists/*

# 4. Dynamic ISO Download
# This script scrapes the Proxmox ISO directory, sorts by version, and grabs the newest one.
RUN echo "🔎 Searching for the latest Proxmox VE ISO..." && \
    BASE_URL="https://enterprise.proxmox.com/iso/" && \
    # Scrape filenames -> Filter for proxmox-ve_*.iso -> Sort by Version -> Take the last one
    LATEST_ISO=$(curl -s $BASE_URL | grep -o 'proxmox-ve_[0-9.]\+-[0-9]\+\.iso' | sort -V | tail -n1) && \
    echo "✅ Found latest version: $LATEST_ISO" && \
    echo "⬇️ Downloading..." && \
    wget -q --show-progress "${BASE_URL}${LATEST_ISO}" -O /proxmox.iso

WORKDIR /data

# 5. The Build Command
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
