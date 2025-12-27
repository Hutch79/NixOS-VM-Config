# Custom NixOS ISO - Build and Deploy

## Overview

This approach creates a **custom NixOS ISO** with your complete configuration baked in. Much simpler than cloud-init for Proxmox!

## How It Works

1. Build custom ISO with your config included
2. Boot ISO in Proxmox VM
3. Run one-command installer
4. System is fully configured and ready to use

## Prerequisites

- A NixOS machine to build the ISO (can be VM or physical)
- About 5 minutes for ISO build
- Proxmox with ability to upload ISO

## Step 1: Build the ISO

**On a NixOS machine with your config:**

```bash
chmod +x build-iso.sh
./build-iso.sh
```

This will:

- ✅ Build custom ISO with your configuration
- ✅ Output location of the ISO file
- ✅ Take ~5 minutes

**Output:** `result/nixos-25.11-x86_64-linux.iso` (or similar)

## Step 2: Upload to Proxmox

```bash
# Copy ISO to Proxmox
scp result/*.iso proxmox-user@proxmox-host:/var/lib/vz/template/iso/

# Or manually upload via Proxmox web UI:
# Storage → Local (or your storage) → Upload ISO
```

## Step 3: Create and Boot VM in Proxmox

1. **Create VM:**
   - VM ID: e.g., 101
   - Name: e.g., `nix-server-01`
   - OS: Linux / Other
   - System: QEMU
   - CPU: 4 cores
   - Memory: 4GB
   - Disk: 20GB+ (System will need < 10GB)

2. **Boot Options:**
   - Select your custom ISO as boot device
   - Start VM

## Step 4: Install from ISO

At the boot prompt, you'll see:

```text
╔═══════════════════════════════════════════════════════════╗
║       NixOS Server Setup - Custom Installation ISO        ║
║                                                           ║
║  Installation will start automatically on boot.           ║
║  Or run manually:                                         ║
║  $ sudo /etc/nixos/install-on-iso.sh [--auto]             ║
║                                                           ║
║  Configuration is already included on this ISO!           ║
╚═══════════════════════════════════════════════════════════╝
```

**The installation *should* run automatically on boot**, or you can run manually:

```bash
sudo bash /etc/nixos/install-on-iso.sh [--auto]
```

The script will:

1. Partition disk (/dev/sda)
2. Format filesystems  
3. Copy your config from ISO
4. Install NixOS with your full configuration
5. Reboot automatically

Total installation time: ~5 minutes

## Step 5: Post-Boot Setup

After reboot, login and:

```bash
# Set user password
sudo passwd luna

# (Optional) Setup netbird
sudo netbird up --setup-key YOUR_SETUP_KEY_HERE
```

Your system is now fully configured!

## Included Configuration

This ISO includes a production-ready NixOS configuration with:

- **Security hardening**: SSH key-only auth, fail2ban, firewall with Docker restrictions, no root login
- **Docker setup**: Rootless Docker with auto-prune, Compose support
- **Monitoring**:
  - Prometheus node metrics (via Alloy)
  - Systemd journal and Docker container logs shipped to Loki (via Alloy)
  - Automatic updates (Saturdays 6 AM with reboot)
  - Weekly garbage collection and store optimization
- **System logging**: Persistent journald with 90-day retention
- **Keyboard/layout**: Swiss German console layout
- **User setup**: Non-root user `luna` with Docker/sudo access

## Updating the ISO

When you update your NixOS configuration:

```bash
# Update your config files
vim configuration.nix

# Rebuild ISO
./build-iso.sh

# Upload new ISO to Proxmox
scp result/*.iso proxmox-user@proxmox-host:/var/lib/vz/template/iso/
```

## Troubleshooting

### ISO won't build

```bash
# Ensure you're on NixOS
uname -a

# Check flake validity
nix flake check
```

### Installation fails

```bash
# View logs
sudo journalctl -xe

# Manual install from ISO
nixos-generate-config --root /mnt
# Edit /mnt/etc/nixos/configuration.nix
nixos-install --root /mnt
```

## Multi-VM Deployment

After creating one VM with the custom ISO:

1. Power off VM
2. Right-click → Convert to template
3. Clone template for new VMs

**Even faster!** No need to rebuild ISO each time.
