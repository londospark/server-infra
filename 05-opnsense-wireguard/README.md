# WireGuard VPN Setup for OPNsense

This directory contains Ansible playbooks to set up WireGuard VPN on your OPNsense firewall for secure remote access to your homelab.

## What This Does

- Installs WireGuard plugin on OPNsense
- Generates server keys
- Provides configuration instructions
- Generates client configurations
- Creates QR codes for mobile devices

## Prerequisites

1. OPNsense firewall already deployed (from `../03-opnsense-deployment`)
2. Public IP address or dynamic DNS
3. Port forwarding set up (if behind another router)

## Quick Start

### 1. Set Up VPN Server

```bash
make setup-vpn
```

This will:
- Install WireGuard on OPNsense
- Generate server keys
- Save keys to `wireguard-server-keys.txt`
- Display configuration instructions

### 2. Configure OPNsense Web UI

Follow the displayed instructions:

1. **Access OPNsense**: https://10.0.0.1
2. **Install Plugin**:
   - System > Firmware > Plugins
   - Install `os-wireguard` (if not already installed)

3. **Enable WireGuard**:
   - VPN > WireGuard > Settings
   - Check "Enable WireGuard"
   - Save

4. **Create Server Instance**:
   - VPN > WireGuard > Servers > Add
   - **Name**: HomeVPN
   - **Public Key**: (copy from terminal output)
   - **Private Key**: (copy from wireguard-server-keys.txt)
   - **Listen Port**: 51820
   - **Tunnel Address**: 10.0.100.1/24
   - **DNS**: 10.0.0.1
   - Save

5. **Create Firewall Rules**:
   
   **WAN Rule** (allow VPN connections):
   - Firewall > Rules > WAN > Add
   - **Action**: Pass
   - **Interface**: WAN
   - **Protocol**: UDP
   - **Destination Port**: 51820
   - **Description**: WireGuard VPN
   - Save & Apply

   **WireGuard Rule** (allow VPN traffic to LAN):
   - Firewall > Rules > WireGuard (group) > Add
   - **Action**: Pass
   - **Interface**: WireGuard (group)
   - **Source**: WireGuard net (10.0.100.0/24)
   - **Destination**: LAN net (10.0.0.0/24)
   - **Description**: WireGuard to LAN
   - Save & Apply

### 3. Create Client Configurations

#### For laptop/desktop:
```bash
make client NAME=laptop IP=10.0.100.10
```

This generates `wireguard-laptop.conf` with all necessary settings.

#### For phone/tablet:
```bash
make client NAME=phone IP=10.0.100.11
make qr NAME=phone
```

Scan the QR code with WireGuard mobile app.

### 4. Add Clients to OPNsense

For each client:

1. **VPN > WireGuard > Peers > Add**
2. **Name**: laptop (or whatever you named it)
3. **Public Key**: (shown in output from `make client`)
4. **Allowed IPs**: 10.0.100.10/32
5. **Endpoint**: (leave empty for road warrior setup)
6. Save & Apply

## Client Management

### Create Multiple Clients

```bash
# Laptop
make client NAME=laptop IP=10.0.100.10

# Phone
make client NAME=phone IP=10.0.100.11

# Tablet
make client NAME=tablet IP=10.0.100.12

# Work laptop
make client NAME=work-laptop IP=10.0.100.13
```

### IP Address Assignment

- **VPN Server**: 10.0.100.1
- **Clients**: 10.0.100.10-254
- **LAN**: 10.0.0.0/24 (accessible through VPN)

### Using Client Configurations

#### Linux/macOS:
```bash
# Copy config
sudo cp wireguard-laptop.conf /etc/wireguard/wg0.conf

# Start VPN
sudo wg-quick up wg0

# Enable on boot
sudo systemctl enable wg-quick@wg0

# Stop VPN
sudo wg-quick down wg0
```

#### Windows:
1. Install [WireGuard for Windows](https://www.wireguard.com/install/)
2. Click "Add Tunnel" > "Import from file"
3. Select `wireguard-laptop.conf`
4. Click "Activate"

#### iOS/Android:
1. Install WireGuard app from App Store/Play Store
2. Scan QR code from `make qr NAME=phone`
3. Activate tunnel

## Testing

### From VPN Client

```bash
# Test VPN connection
ping 10.0.100.1

# Test LAN access
ping 10.0.0.1      # OPNsense
ping 10.0.0.21     # dev-host
ping 10.0.0.22     # home-host (Grocy!)
ping 10.0.0.23     # projects-host

# Access web services
curl http://10.0.0.22  # Grocy
curl http://grocy.home.lan  # If DNS works
```

### View Status on OPNsense

- **VPN > WireGuard > Status**
- Shows connected clients
- Shows handshake times
- Shows data transfer

## Security Notes

- **Split Tunnel**: Clients only route homelab traffic (10.0.0.0/24, 10.0.100.0/24) through VPN
- **Full Tunnel**: Edit `AllowedIPs` in client config to `0.0.0.0/0` for all traffic through VPN
- **Firewall**: WAN access is restricted to UDP 51820 only
- **Keys**: Server private key is stored on OPNsense only
- **DNS**: Clients use OPNsense (10.0.0.1) for DNS when connected

## Troubleshooting

### Can't connect to VPN

1. **Check firewall rule**:
   - Firewall > Log Files > Live View
   - Look for blocked UDP 51820 packets

2. **Verify public IP**:
   ```bash
   curl ifconfig.me
   ```
   Update client config `Endpoint` with correct IP

3. **Check OPNsense WireGuard status**:
   - VPN > WireGuard > Status
   - Server should show "up"

### Connected but can't reach LAN

1. **Check WireGuard firewall rule**:
   - Firewall > Rules > WireGuard
   - Rule should allow WireGuard net to LAN net

2. **Verify routing**:
   ```bash
   # From client
   ip route | grep 10.0.0.0
   ```

3. **Test connectivity**:
   ```bash
   ping 10.0.100.1  # VPN gateway
   ping 10.0.0.1    # OPNsense LAN
   ```

### Dynamic DNS Setup

If your public IP changes:

1. **Set up Dynamic DNS** in OPNsense:
   - Services > Dynamic DNS > Settings
   - Add provider (Cloudflare, DuckDNS, etc.)

2. **Update client configs**:
   ```conf
   [Peer]
   Endpoint = your-domain.duckdns.org:51820
   ```

## Advanced Configuration

### Full Tunnel (Route All Traffic)

Edit client config:
```conf
[Peer]
AllowedIPs = 0.0.0.0/0  # All IPv4 traffic
```

### Custom DNS

Edit client config:
```conf
[Interface]
DNS = 1.1.1.1, 1.0.0.1  # Cloudflare DNS
```

### Kill Switch (Linux)

```bash
# Add to client config
PostUp = iptables -I OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
PreDown = iptables -D OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
```

## Maintenance

### Rotate Keys

```bash
# Generate new server keys
make setup-vpn

# Update OPNsense with new keys
# Regenerate all client configs
```

### Remove Client

1. **OPNsense**: VPN > WireGuard > Peers > Delete
2. **Local**: `rm wireguard-clientname.conf`

### View Logs

OPNsense:
- **System > Log Files > Backend**
- Filter for "wireguard"

## Integration with Docker Hosts

Once VPN is set up, you can access all services remotely:

```
Phone/Laptop (anywhere)
    ↓ WireGuard VPN
OPNsense (10.0.100.1)
    ↓ LAN
Docker Hosts (10.0.0.21-23)
    ↓
Grocy, Gitea, etc.
```

Access Grocy from your phone:
- Connect WireGuard VPN
- Browse to: http://10.0.0.22 or http://grocy.home.lan
