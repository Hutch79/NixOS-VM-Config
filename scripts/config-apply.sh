#!/usr/bin/env bash
# Script to apply NixOS configs from ~/nixos to /etc/nixos
# Preserves hardware-configuration.nix which is system-specific

set -euo pipefail

USER_CONFIG_DIR="$HOME/nixos"
SYSTEM_CONFIG_DIR="/etc/nixos"
APPLYIGNORE_FILE="$USER_CONFIG_DIR/.applyignore"

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

# Build exclusion list from .applyignore
EXCLUDE_PATTERNS=()
if [ -f "$APPLYIGNORE_FILE" ]; then
  while IFS= read -r pattern; do
    # Skip empty lines and comments
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
    EXCLUDE_PATTERNS+=("$pattern")
  done < "$APPLYIGNORE_FILE"
else
  echo -e "${YELLOW}Warning: .applyignore not found, using default exclusions${NC}"
  EXCLUDE_PATTERNS=("hardware-configuration.nix" "flake.lock" ".git" "result")
fi

FILES_TO_OVERWRITE=""
if [ -d "$SYSTEM_CONFIG_DIR" ]; then
  # Find files in /etc/nixos that differ from ~/nixos
  while IFS= read -r file; do
    rel_path="${file#$SYSTEM_CONFIG_DIR/}"
    
    # Check if file matches any exclusion pattern
    should_skip=false
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
      if [[ "$rel_path" == $pattern* ]] || [[ "$rel_path" == *"/$pattern"* ]] || [[ "$rel_path" == "$pattern" ]]; then
        should_skip=true
        break
      fi
    done
    
    if [ "$should_skip" = false ]; then
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

# Build rsync exclude arguments from .applyignore
RSYNC_EXCLUDES=()
if [ -f "$APPLYIGNORE_FILE" ]; then
  while IFS= read -r pattern; do
    # Skip empty lines and comments
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
    RSYNC_EXCLUDES+=(--exclude "$pattern")
  done < "$APPLYIGNORE_FILE"
else
  # Default exclusions if .applyignore doesn't exist
  RSYNC_EXCLUDES=(--exclude '.git' --exclude 'hardware-configuration.nix' --exclude 'flake.lock' --exclude 'result')
fi

# Run rsync with itemize-changes to track what changed
# -c uses checksum instead of timestamp/size for change detection
# -r recursive, -l copy symlinks, -t preserve times (but we check with -c)
# --delete removes files in dest that aren't in source
RSYNC_OUTPUT=$(sudo rsync -rlc --delete --itemize-changes \
  "${RSYNC_EXCLUDES[@]}" \
  "$USER_CONFIG_DIR/" "$SYSTEM_CONFIG_DIR/" 2>&1)

# Restore hardware-configuration.nix before checking for changes
if [ -n "$HARDWARE_BACKUP" ] && [ -f "$HARDWARE_BACKUP" ]; then
  sudo cp "$HARDWARE_BACKUP" "$HARDWARE_CONFIG"
  rm "$HARDWARE_BACKUP"
fi

# Check if any files were actually changed
# When using -c (checksum), rsync only shows items in itemize output if they're being transferred
FILES_CHANGED=$(echo "$RSYNC_OUTPUT" | grep -E '^>f|^\*deleting|^<f' | wc -l || true)

if [ "$FILES_CHANGED" -gt 0 ]; then
  echo -e "${GREEN}✓ Configuration files updated${NC}"
  echo -e "${GREEN}✓ hardware-configuration.nix preserved${NC}"
  CHANGES_APPLIED=true
else
  echo -e "${GREEN}✓ No changes detected - configurations are already in sync${NC}"
  CHANGES_APPLIED=false
fi

# Set proper ownership
sudo chown -R root:root "$SYSTEM_CONFIG_DIR"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Config applied successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ "$CHANGES_APPLIED" = true ]; then
  echo -e "${YELLOW}Configuration changes detected!${NC}"
  echo ""
  read -p "Would you like to rebuild the system now? (yes/no) [no]: " -r REBUILD_CONFIRM
  REBUILD_CONFIRM=${REBUILD_CONFIRM:-no}
  
  if [[ $REBUILD_CONFIRM =~ ^[Yy][Ee][Ss]$ ]]; then
    echo ""
    echo "Running nixos-rebuild switch..."
    cd "$SYSTEM_CONFIG_DIR" && sudo nixos-rebuild switch --flake .
  else
    echo ""
    echo "Skipping rebuild. To rebuild later, run:"
    echo -e "${BLUE}  nix-rebuild${NC}"
  fi
else
  echo "No rebuild needed - system is already up to date."
fi
echo ""
