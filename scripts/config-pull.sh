#!/usr/bin/env bash
# Script to safely pull updated NixOS configs from remote git repo
# Checks for local changes and asks for confirmation before overwriting

set -euo pipefail

REPO_URL="https://github.com/Hutch79/NixOS-VM-Config.git"
CONFIG_DIR="/etc/nixos"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}NixOS Config Pull - Safe Update${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Note: hardware-configuration.nix is hardware-specific and will be ignored"
echo ""

# Check if we're in a git repository
if [ ! -d "$CONFIG_DIR/.git" ]; then
  echo -e "${RED}ERROR: $CONFIG_DIR is not a git repository${NC}"
  echo "This script requires the config directory to be a git repository."
  exit 1
fi

cd "$CONFIG_DIR"

# Mark directory as safe for git operations (handles permission issues)
git config --global --add safe.directory "$CONFIG_DIR" 2>/dev/null || true

# Check for local changes
echo "Checking for local changes..."
LOCAL_CHANGES=$(git status --porcelain)

if [ -n "$LOCAL_CHANGES" ]; then
  echo -e "${YELLOW}⚠ Local changes detected!${NC}"
  echo ""
  echo -e "${YELLOW}Local modifications:${NC}"
  echo "$LOCAL_CHANGES"
  echo ""
  
  # Ask for confirmation
  read -p "Overwrite local changes and pull from remote? (yes/no): " -r CONFIRM
  echo ""
  
  if [[ ! $CONFIRM =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Cancelled. Local changes preserved.${NC}"
    exit 0
  fi
  
  # Stash local changes with timestamp
  STASH_NAME="auto-stash-$(date '+%Y-%m-%d_%H-%M-%S')"
  echo "Stashing local changes as: $STASH_NAME"
  git stash push -m "$STASH_NAME"
  echo -e "${GREEN}✓ Local changes stashed${NC}"
fi

# Fetch from remote
echo ""
echo "Fetching from remote repository..."
git fetch origin || {
  echo -e "${RED}ERROR: Failed to fetch from remote${NC}"
  exit 1
}

# Check if main/master branch exists on remote
BRANCH="main"
if ! git rev-parse --verify origin/$BRANCH >/dev/null 2>&1; then
  BRANCH="master"
  if ! git rev-parse --verify origin/$BRANCH >/dev/null 2>&1; then
    echo -e "${RED}ERROR: Could not find main or master branch on remote${NC}"
    exit 1
  fi
fi

echo ""
echo -e "${BLUE}Pulling from remote branch: $BRANCH${NC}"

# Force reset to remote branch - overwrite local history to match remote exactly
git reset --hard origin/$BRANCH
echo -e "${GREEN}✓ Local history reset to match remote${NC}"
echo ""

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Config pull complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "To apply the new configuration, run:"
echo -e "${BLUE}  nix-rebuild${NC}"
echo "or"
echo -e "${BLUE}  nix-update${NC}"
