# Custom NixOS ISO - Build and Deploy

Create a **NixOS ISO** including customized configuration packaged into it.

## How It Works

1. Build custom ISO with your config included
2. Boot ISO in VM
3. Run one-command installer
4. System is fully configured and ready to use

## Files

- **build-iso.sh** - Build bootable NixOS installer ISO
- **install-on-iso.sh** - Installation script (runs on ISO)
- **iso-configuration.nix** - Minimal config for installer ISO

## Prerequisites

- A NixOS machine to build the ISO (can be VM or physical)

## Step 1: Build the ISO

Run from the project root directory:

```bash
./install/build-iso.sh
```

This will:

- ✅ Build custom ISO with your configuration
- ✅ Output location of the ISO file

**Output:** `result/iso/nixos-minimal-*.iso`

## Step 2: Boot and Install

Boot the ISO in your VM. The installation will start automatically, or you can run manually:

```bash
sudo /etc/nixos/install-on-iso.sh
```

The script will:

1. Partition disk (/dev/sda) with MBR
   - Boot partition: 2GB
   - Root partition: remainder of disk
2. Format filesystems (ext4)
3. Clone config from repo or copy from ISO as fallback
4. Generate hardware configuration
5. Install NixOS with your full configuration
6. Initialize git repository in /etc/nixos
7. Reboot automatically

## Step 3: Post-Boot Setup

After reboot, login as `luna` via SSH. The git repository is already initialized in `/etc/nixos`.

**To pull configuration updates:**

```bash
nix-pull
```

This safely updates system configuration from remote, checking for local changes and stashing any modifications before pulling.

**To apply configuration changes:**

```bash
nix-rebuild
```
