#!/usr/bin/env bash
# Installation script that runs from the custom NixOS ISO
# This installs your full NixOS configuration automatically
# Use --auto to run without prompts

set -euo pipefail

AUTO=false
if [ "${1:-}" = "--auto" ]; then
  AUTO=true
fi

DISK="/dev/sda"

# Enable logging to file after we know where we're going
LOG_FILE="/tmp/install.log"

# Start logging to both console and file
exec 1> >(tee "$LOG_FILE")
exec 2>&1

echo "=========================================="
echo "NixOS Server Setup - ISO Installation"
echo "=========================================="
echo ""
echo "Logging to: $LOG_FILE"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo "ERROR: This script must be run as root (use sudo)"
  exit 1
fi

# Validate disk exists
if [ ! -b "$DISK" ]; then
  echo "ERROR: Disk $DISK does not exist or is not a block device"
  exit 1
fi

# Set default hostname
HOSTNAME="Nix-Server"

# Validate disk
if [ ! -b "$DISK" ]; then
  echo "ERROR: Disk $DISK does not exist or is not a block device"
  exit 1
fi

# Display summary
echo ""
echo "INSTALLATION SUMMARY:"
echo "=========================================="
echo "  Target Disk:     $DISK"
echo "  Network Config:  DHCP (default)"
echo ""
echo "WARNING: This will ERASE all data on $DISK"
echo ""
if ! $AUTO; then
  read -p "Press Enter to continue, or Ctrl+C to cancel..."
fi

# Check if we're still root after the prompts
if [ "$EUID" -ne 0 ]; then 
  echo "ERROR: This script must be run as root (use sudo)"
  exit 1
fi

# Unmount any existing mounts on target disk
echo "Cleaning up any existing mounts..."
for partition in "${DISK}"*; do
  if mountpoint -q "$partition" 2>/dev/null; then
    umount "$partition" || true
  fi
done

# Partition the disk
echo ""
echo "[1/5] Partitioning disk..."
# Use MBR (msdos) for compatibility with BIOS boot
parted -s "$DISK" -- mklabel msdos
# Create boot partition (2GB)
parted -s "$DISK" -- mkpart primary ext4 1MB 2048MB
parted -s "$DISK" -- set 1 boot on
# Create root partition (remainder)
parted -s "$DISK" -- mkpart primary ext4 2048MB -0

# Wait for devices to be created
sleep 1

# Format
echo "[2/5] Formatting partitions..."
mkfs.ext4 -F "${DISK}1" || mkfs.ext4 -F "${DISK}p1"
mkfs.ext4 -F "${DISK}2" || mkfs.ext4 -F "${DISK}p2"

# Determine partition naming (sda1 vs sdap1)
if [ -b "${DISK}1" ]; then
  BOOT_PART="${DISK}1"
  ROOT_PART="${DISK}2"
else
  BOOT_PART="${DISK}p1"
  ROOT_PART="${DISK}p2"
fi

# Mount
echo "[3/5] Mounting filesystems..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$BOOT_PART" /mnt/boot

# Verify mounts
if ! mountpoint -q /mnt; then
  echo "ERROR: Failed to mount root filesystem"
  exit 1
fi

# Prepare configuration
REPO_URL="https://github.com/Hutch79/Server-NixConfig.git"
mkdir -p /mnt/etc/nixos

# Try to clone from git repository if network is available
echo "[4/5] Preparing configuration..."
if timeout 5 ping -c 1 github.com &>/dev/null; then
  echo "Network connectivity detected. Attempting to clone from git repository..."
  
  if git clone "$REPO_URL" /mnt/etc/nixos 2>&1 | grep -q "fatal"; then
    echo "Git clone failed, falling back to ISO configuration..."
    CLONE_FAILED=true
  else
    echo "✓ Successfully cloned configuration from git repository"
    CLONE_FAILED=false
  fi
else
  echo "No network connectivity. Using configuration from ISO..."
  CLONE_FAILED=true
fi

# If git clone failed, copy from ISO
if [ "$CLONE_FAILED" = true ]; then
  if [ ! -f /etc/nixos/configuration.nix ]; then
    echo "ERROR: /etc/nixos/configuration.nix not found on ISO"
    exit 1
  fi
  
  cp /etc/nixos/configuration.nix /mnt/etc/nixos/
  cp /etc/nixos/user-config.nix /mnt/etc/nixos/
  cp /etc/nixos/aliases.nix /mnt/etc/nixos/
  cp /etc/nixos/monitoring.nix /mnt/etc/nixos/
  cp /etc/nixos/flake.nix /mnt/etc/nixos/
  cp /etc/nixos/flake.lock /mnt/etc/nixos/
  cp /etc/nixos/compose.yml /mnt/etc/nixos/ 2>/dev/null || true
  
  # Copy scripts folder
  mkdir -p /mnt/etc/nixos/scripts
  cp /etc/nixos/scripts/* /mnt/etc/nixos/scripts/ 2>/dev/null || true
fi

# Generate hardware config
echo "[5/5] Generating hardware configuration..."
if ! nixos-generate-config --root /mnt; then
  echo "ERROR: Failed to generate hardware configuration"
  exit 1
fi

# Install NixOS with your full configuration
echo "Installing NixOS (this may take 15-30 minutes)..."
if ! nixos-install --root /mnt --no-root-passwd --show-trace; then
  echo "ERROR: NixOS installation failed. Check /mnt/install.log for details."
  exit 1
fi

# Copy log to installed system
cp "$LOG_FILE" /mnt/var/log/install.log 2>/dev/null || true

# Initialize or verify git repository in the installed system
echo ""
echo "Setting up git repository for config management..."
REPO_URL="https://github.com/Hutch79/Server-NixConfig.git"

# Use GIT_WORK_TREE and GIT_DIR to work with the mounted filesystem directly
export GIT_WORK_TREE="/mnt/etc/nixos"
export GIT_DIR="/mnt/etc/nixos/.git"

# Check if already a git repo (from clone)
if [ ! -d "$GIT_DIR" ]; then
  echo "Initializing new git repository..."
  git init "$GIT_WORK_TREE" || {
    echo -e "ERROR: Failed to initialize git repository"
    exit 1
  }
  git config user.email 'nix@local'
  git config user.name 'NixOS Local'
  git add -A
  git commit -m 'Initial NixOS configuration snapshot' || echo "WARNING: Could not create initial commit"
  git remote add origin "$REPO_URL"
  echo "✓ Git repository initialized"
else
  echo "Git repository already exists (from clone)"
  # Ensure user config is set
  git config user.email 'nix@local' || true
  git config user.name 'NixOS Local' || true
  echo "✓ Git repository verified"
fi

echo "✓ Git repository ready for config management"

echo ""
echo "=========================================="
echo "✓ Installation Complete!"
echo "=========================================="
echo ""
echo "Your system will boot with:"
echo "  ✓ Network: DHCP"
echo "  ✓ Docker with auto-prune"
echo "  ✓ Fail2ban enabled"
echo "  ✓ Git repo initialized for config pulls"
echo ""
echo "Post-installation:"
echo "  1. Log in as: luna"
echo "  2. Find IP address: ip addr show"
echo "  3. To rebuild configuration: sudo nixos-rebuild switch --flake .#Nix-Server"
echo "  4. To pull updates: nix-pull"
echo ""
if ! $AUTO; then
  read -p "Press Enter to reboot..."
fi
reboot
