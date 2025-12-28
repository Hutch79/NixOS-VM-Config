#!/usr/bin/env bash
# Script to apply NixOS configs from ~/nixos to /etc/nixos
# Preserves hardware-configuration.nix which is system-specific

set -euo pipefail

USER_CONFIG_DIR="$HOME/nixos"
SYSTEM_CONFIG_DIR="/etc/nixos"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}NixOS Config Apply${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if source directory exists
if [ ! -d "$USER_CONFIG_DIR" ]; then
  echo -e "${RED}ERROR: $USER_CONFIG_DIR does not exist${NC}"
  echo "Run 'nix-pull' first to clone the configuration repository."
  exit 1
fi

# Check if flake.nix exists in source
if [ ! -f "$USER_CONFIG_DIR/flake.nix" ]; then
  echo -e "${RED}ERROR: $USER_CONFIG_DIR/flake.nix not found${NC}"
  echo "The source directory doesn't appear to be a valid NixOS configuration."
  exit 1
fi

echo "Source:      $USER_CONFIG_DIR"
echo "Destination: $SYSTEM_CONFIG_DIR"
echo ""

# Check what files will be overwritten
echo "Checking for files that will be overwritten..."
FILES_TO_OVERWRITE=""
if [ -d "$SYSTEM_CONFIG_DIR" ]; then
  # Find files in /etc/nixos that differ from ~/nixos (excluding hardware-configuration.nix)
  while IFS= read -r file; do
    rel_path="${file#$SYSTEM_CONFIG_DIR/}"
    # Skip hardware-configuration.nix, .git, and result
    if [[ "$rel_path" != "hardware-configuration.nix" ]] && \
       [[ "$rel_path" != ".git"* ]] && \
       [[ "$rel_path" != "result"* ]]; then
      source_file="$USER_CONFIG_DIR/$rel_path"
      if [ -f "$source_file" ]; then
        # Compare files
        if ! cmp -s "$file" "$source_file" 2>/dev/null; then
          FILES_TO_OVERWRITE+="  - $rel_path\n"
        fi
      fi
    fi
  done < <(find "$SYSTEM_CONFIG_DIR" -type f 2>/dev/null)
fi

if [ -n "$FILES_TO_OVERWRITE" ]; then
  echo -e "${YELLOW}⚠ WARNING: The following files in /etc/nixos will be overwritten:${NC}"
  echo ""
  echo -e "$FILES_TO_OVERWRITE"
  echo -e "${RED}Any manual changes to these files will be IRREVERSIBLY LOST!${NC}"
  echo ""
  read -p "Continue with apply? (yes/no): " -r CONFIRM
  
  if [[ ! $CONFIRM =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Cancelled. No changes made.${NC}"
    exit 0
  fi
  echo ""
else
  echo "No conflicting changes detected."
  echo ""
fi

# Backup hardware-configuration.nix if it exists
HARDWARE_CONFIG="$SYSTEM_CONFIG_DIR/hardware-configuration.nix"
HARDWARE_BACKUP=""
if [ -f "$HARDWARE_CONFIG" ]; then
  echo "Preserving hardware-configuration.nix..."
  HARDWARE_BACKUP=$(mktemp)
  cp "$HARDWARE_CONFIG" "$HARDWARE_BACKUP"
fi

# Copy all files from user config to system config
echo "Copying configuration files..."
sudo rsync -av --delete \
  --exclude '.git' \
  --exclude 'hardware-configuration.nix' \
  --exclude 'result' \
  "$USER_CONFIG_DIR/" "$SYSTEM_CONFIG_DIR/"

# Restore hardware-configuration.nix
if [ -n "$HARDWARE_BACKUP" ] && [ -f "$HARDWARE_BACKUP" ]; then
  sudo cp "$HARDWARE_BACKUP" "$HARDWARE_CONFIG"
  rm "$HARDWARE_BACKUP"
  echo -e "${GREEN}✓ hardware-configuration.nix preserved${NC}"
fi

# Set proper ownership
sudo chown -R root:root "$SYSTEM_CONFIG_DIR"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Config applied successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "To rebuild the system with new configuration, run:"
echo -e "${BLUE}  nix-rebuild${NC}"
