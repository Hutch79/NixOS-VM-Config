#!/usr/bin/env bash
# Script to build the custom NixOS ISO
# Run this on a machine with NixOS installed

set -e

echo "=========================================="
echo "Building Custom NixOS ISO"
echo "=========================================="
echo ""

# Check if we're on NixOS
if [ ! -f /etc/os-release ] || ! grep -q "NixOS" /etc/os-release; then
  echo "ERROR: This script must be run on NixOS"
  exit 1
fi

# Navigate to parent directory where flake.nix is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Build the ISO
echo "Building custom NixOS ISO (this may take 10-15 minutes)..."
nix build ".#nixosConfigurations.iso.config.system.build.isoImage" -L

# Find the ISO - try direct path first
if [ -f "result/iso/nixos-minimal-"*.iso ]; then
  ISO_PATH=$(ls -1 result/iso/nixos-minimal-*.iso | head -1)
elif [ -f "result/iso/*.iso" ]; then
  ISO_PATH=$(ls -1 result/iso/*.iso | head -1)
else
  ISO_PATH=""
fi

if [ -z "$ISO_PATH" ]; then
  echo "ERROR: ISO not found after build"
  exit 1
fi

echo ""
echo "=========================================="
echo "✓ ISO Build Complete!"
echo "=========================================="
echo ""
echo "ISO Location: $ISO_PATH"
echo ""
echo "Next steps:"
echo "1. Copy the ISO to Proxmox:"
echo "   scp $ISO_PATH proxmox-user@proxmox-host:/var/lib/vz/template/iso/"
echo ""
echo "2. In Proxmox:"
echo "   - Create a new VM"
echo "   - Select the custom ISO as boot device"
echo "   - Start the VM"
echo "   - At the login prompt, run: sudo /etc/nixos/install-on-iso.sh /dev/sda"
echo ""
echo "3. System will reboot and be ready to use!"
echo ""
