#!/usr/bin/env bash
# Script to safely pull updated NixOS configs from remote git repo
# Pulls to ~/nixos and then applies to /etc/nixos

set -euo pipefail

REPO_URL="https://github.com/Hutch79/NixOS-VM-Config.git"
USER_CONFIG_DIR="$HOME/nixos"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

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

# Check if user config directory exists, if not clone it
if [ ! -d "$USER_CONFIG_DIR" ]; then
  echo "First time setup: Cloning repository to $USER_CONFIG_DIR..."
  git clone "$REPO_URL" "$USER_CONFIG_DIR" || {
    echo -e "${RED}ERROR: Failed to clone repository${NC}"
    exit 1
  }
  echo -e "${GREEN}✓ Repository cloned successfully${NC}"
else
  # Directory exists, pull updates
  cd "$USER_CONFIG_DIR"
  
  # Mark directory as safe for git operations
  git config --global --add safe.directory "$USER_CONFIG_DIR" 2>/dev/null || true

  # Check for local changes
  echo "Checking for local changes..."
  LOCAL_CHANGES=$(git status --porcelain)

  if [ -n "$LOCAL_CHANGES" ]; then
    echo -e "${YELLOW}⚠ Local changes detected!${NC}"
    echo ""
    echo -e "${YELLOW}Local modifications:${NC}"
    echo "$LOCAL_CHANGES"
    echo ""
    
    # Show diff of changes
    echo -e "${BLUE}Changes to be overwritten:${NC}"
    echo "----------------------------------------"
    git diff --color=always || git diff
    echo "----------------------------------------"
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

  # Force reset to remote branch
  git reset --hard origin/$BRANCH
  echo -e "${GREEN}✓ Repository updated${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Config pull complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Apply the configuration
echo "Applying configuration to /etc/nixos..."
echo ""
bash "$SCRIPT_DIR/config-apply.sh"
