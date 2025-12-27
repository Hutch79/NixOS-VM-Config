#!/usr/bin/env bash
# Initialize NixOS config directory as a git repository
# Run this once after initial installation before using nix-pull

set -euo pipefail

CONFIG_DIR="/etc/nixos"
REPO_URL="https://github.com/Hutch79/Server-NixConfig.git"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}NixOS Config - Git Repository Init${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if already a git repo
if [ -d "$CONFIG_DIR/.git" ]; then
  echo -e "${YELLOW}⚠ $CONFIG_DIR is already a git repository${NC}"
  read -p "Reinitialize? (yes/no): " -r CONFIRM
  echo ""
  
  if [[ ! $CONFIRM =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
  
  rm -rf "$CONFIG_DIR/.git"
fi

# Check if running as root (needed for /etc/nixos)
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}ERROR: This script must be run as root (use sudo)${NC}"
  exit 1
fi

cd "$CONFIG_DIR"

echo "Initializing git repository..."
git init

echo "Setting git user (for commit metadata)..."
git config user.email "nix@local"
git config user.name "NixOS Local"

echo "Adding all files..."
git add .

echo "Creating initial commit..."
git commit -m "Initial NixOS configuration snapshot"

echo ""
echo "Adding remote repository..."
git remote add origin "$REPO_URL"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Git repository initialized!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "You can now use:"
echo -e "${BLUE}  nix-pull${NC} - Pull updates from remote"
echo ""
echo "To fetch and review remote changes first:"
echo -e "${BLUE}  cd /etc/nixos && git fetch origin${NC}"
