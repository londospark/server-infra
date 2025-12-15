# Proxmox VE Automated ISO Builder

This project automates the creation of a custom Proxmox VE ISO with pre-configured installation answers baked in. The Docker container downloads the latest Proxmox VE ISO, embeds your `answer.toml` configuration, and produces a headless-ready installation image that can be flashed to a USB stick.

## Prerequisites

Before running this project, ensure you have the following installed:

### Required
- **Docker** (version 20.10+)
- **Docker Compose** (version 2.0+)
  - Installation: [Install Docker Desktop](https://www.docker.com/products/docker-desktop) (includes Compose) or [install separately](https://docs.docker.com/compose/install/)

### For USB Flashing
- **Linux/Mac**: Built-in tools (dd, diskutil, or third-party tools)
- **Windows**: [Rufus](https://rufus.ie/) (recommended) or [Balena Etcher](https://www.balena.io/etcher/)
- **Alternative (all platforms)**: [Balena Etcher](https://www.balena.io/etcher/) - user-friendly cross-platform tool

## Configuration

The `answer.toml` file contains the Proxmox VE installation answers. Customize this file before building:

```toml
[global]
keyboard = "en-gb"        # Keyboard layout
country = "gb"            # Country code
fqdn = "pve.home.lan"     # Fully qualified domain name
mailto = "admin@home.lan"  # Admin email
timezone = "Europe/London" # Your timezone
root_password = "ChangeMe123!"  # Change this!
reboot_on_error = true

[network]
source = "from-dhcp"      # Use DHCP or "from-iso" for static config

[disk-setup]
filesystem = "zfs"        # Filesystem type (zfs, ext4, etc.)
zfs.raid = "raid0"        # RAID level (raid0, raid1, raid10)
zfs.ashift = 12           # ZFS ashift value
zfs.compress = "on"       # Enable compression
disk_list = ["sda"]       # Disk(s) to install to
```

## Running the Docker Container

### Step 1: Build and Run

Navigate to this folder and run:

```bash
docker compose up --build
```

This will:
1. Build the Docker image
2. Download the latest Proxmox VE ISO from the official repository
3. Embed your `answer.toml` into the ISO
4. Output `proxmox-headless.iso` in the current directory

### Step 2: Monitor the Build

The container will display progress messages. Once complete, you should see:
```
🎉 Success! Your custom image is ready: proxmox-headless.iso
```

The generated ISO file will be in the current directory and ready to flash.

## Flashing the ISO to a USB Stick

### Windows

#### Using Rufus (Recommended)

1. Download and launch [Rufus](https://rufus.ie/)
2. Insert your USB stick (8GB+ recommended)
3. In Rufus:
   - **Device**: Select your USB stick
   - **Boot selection**: Click **SELECT** and choose `proxmox-headless.iso`
   - **Partition scheme**: MBR
   - **File system**: ISO 9660
   - Click **START** and confirm the warning
4. Wait for completion (~5-10 minutes)
5. Eject the USB stick safely

#### Using Balena Etcher

1. Download and install [Balena Etcher](https://www.balena.io/etcher/)
2. Insert your USB stick
3. Open Balena Etcher and:
   - Click **Flash from file** and select `proxmox-headless.iso`
   - Click **Select target** and choose your USB stick
   - Click **Flash** and wait for completion

### Linux

#### Using `dd` (Command Line)

1. Identify your USB stick:
   ```bash
   lsblk
   # Look for your device, e.g., /dev/sdb (NOT /dev/sdb1)
   ```

2. Unmount the USB stick (if mounted):
   ```bash
   sudo umount /dev/sdX*  # Replace X with your device letter
   ```

3. Flash the ISO:
   ```bash
   sudo dd if=proxmox-headless.iso of=/dev/sdX bs=4M status=progress conv=fsync
   # Replace /dev/sdX with your device (e.g., /dev/sdb)
   ```

4. Eject safely:
   ```bash
   sudo eject /dev/sdX
   ```

#### Using Balena Etcher (GUI)

1. Install Balena Etcher:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install balena-etcher
   
   # Fedora
   sudo dnf install balena-etcher
   ```

2. Open Balena Etcher and follow the same steps as Windows (above)

### macOS

#### Using Balena Etcher (Recommended - GUI)

1. Download and install [Balena Etcher](https://www.balena.io/etcher/)
2. Insert your USB stick
3. Open Balena Etcher and:
   - Click **Flash from file** and select `proxmox-headless.iso`
   - Click **Select target** and choose your USB stick
   - Click **Flash** and wait for completion

#### Using `diskutil` (Command Line)

1. Identify your USB stick:
   ```bash
   diskutil list
   # Look for your device, e.g., /dev/disk2
   ```

2. Unmount the USB stick:
   ```bash
   diskutil unmountDisk /dev/diskX  # Replace X with your device number
   ```

3. Convert the ISO to IMG format (optional, for better compatibility):
   ```bash
   hdiutil convert proxmox-headless.iso -format UDRO -o proxmox-headless.img
   ```

4. Flash the image:
   ```bash
   sudo dd if=proxmox-headless.iso of=/dev/rdiskX bs=4m  # Use rdiskX for faster flashing
   # Replace X with your device number
   ```

5. Eject safely:
   ```bash
   diskutil eject /dev/diskX
   ```

## Booting from the USB Stick

1. Insert the USB stick into the target machine
2. Restart the machine and enter the BIOS/UEFI boot menu (typically F12, F2, ESC, or DEL during startup)
3. Select the USB stick as the boot device
4. The Proxmox VE installation will begin automatically with your pre-configured answers

## Troubleshooting

### Docker Build Fails
- Ensure you have internet connectivity and sufficient disk space (~2GB)
- Check that Docker daemon is running: `docker ps`

### USB Stick Not Detected
- Try a different USB port or cable
- Ensure the USB stick is 8GB or larger
- On Linux, verify with `lsblk` or `sudo parted -l`
- On macOS, verify with `diskutil list`

### Installation Doesn't Auto-Install
- Verify that your `answer.toml` is correctly formatted
- Ensure the ISO was generated successfully (check file size > 800MB)
- Try booting in UEFI mode instead of Legacy BIOS (or vice versa)

## Additional Resources

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox Auto-Install Assistant](https://pve.proxmox.com/wiki/Automated_Installation)
- [ZFS Documentation](https://openzfs.org/wiki/Main_Page)

## License

Refer to the parent repository's license.
