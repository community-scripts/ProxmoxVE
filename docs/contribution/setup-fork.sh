#!/bin/bash

################################################################################
# ProxmoxVE Fork Setup Script
#
# Automatically configures documentation and scripts for your fork
# Detects your GitHub username and repository from git config
# Updates all hardcoded links to point to your fork
#
# Usage:
#   ./setup-fork.sh                    # Auto-detect from git config (updates misc/ only)
#   ./setup-fork.sh YOUR_USERNAME      # Specify username (updates misc/ only)
#   ./setup-fork.sh YOUR_USERNAME REPO_NAME  # Specify both (updates misc/ only)
#   ./setup-fork.sh --full             # Update all files including ct/, install/, vm/, etc.
#
# Examples:
#   ./setup-fork.sh john               # Uses john/ProxmoxVE, updates misc/ only
#   ./setup-fork.sh john my-fork       # Uses john/my-fork, updates misc/ only
#   ./setup-fork.sh --full             # Auto-detect + update all files
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REPO_NAME="ProxmoxVE"
USERNAME=""
AUTO_DETECT=true
UPDATE_ALL=false

################################################################################
# FUNCTIONS
################################################################################

print_header() {
  echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC} ProxmoxVE Fork Setup Script"
  echo -e "${BLUE}║${NC} Configuring for your fork..."
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_info() {
  echo -e "${BLUE}ℹ${NC}  $1"
}

print_success() {
  echo -e "${GREEN}✓${NC}  $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC}  $1"
}

print_error() {
  echo -e "${RED}✗${NC}  $1"
}

# Detect username from git remote
detect_username() {
  local remote_url

  # Try to get from origin
  if ! remote_url=$(git config --get remote.origin.url 2>/dev/null); then
    return 1
  fi

  # Extract username from SSH or HTTPS URL
  if [[ $remote_url =~ git@github.com:([^/]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ $remote_url =~ github.com/([^/]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    return 1
  fi
}

# Detect repo name from git remote
detect_repo_name() {
  local remote_url

  if ! remote_url=$(git config --get remote.origin.url 2>/dev/null); then
    return 1
  fi

  # Extract repo name (remove .git if present)
  if [[ $remote_url =~ /([^/]+?)(.git)?$ ]]; then
    local repo="${BASH_REMATCH[1]}"
    echo "${repo%.git}"
  else
    return 1
  fi
}

# Ask user for confirmation
confirm() {
  local prompt="$1"
  local response

  echo -ne "${YELLOW}${prompt} (y/n)${NC} "
  read -r response
  [[ $response =~ ^[Yy]$ ]]
}

# Update links in files
update_links() {
  local old_repo="community-scripts"
  local old_name="ProxmoxVE"
  local new_owner="$1"
  local new_repo="$2"
  local files_updated=0

  print_info "Scanning for hardcoded links..."

  # Change to repo root
  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

  # Determine search path
  local search_path="$repo_root/misc"
  if [[ "$UPDATE_ALL" == "true" ]]; then
    search_path="$repo_root"
    print_info "Searching all files (--full mode)"
  else
    print_info "Searching misc/ directory only (core functions)"
  fi

  echo ""

  # Find all files containing the old repo reference
  while IFS= read -r file; do
    # Count occurrences
    local count=$(grep -E -c "(github.com|githubusercontent.com)/$old_repo/$old_name" "$file" 2>/dev/null || echo 0)

    if [[ $count -gt 0 ]]; then
      # Backup original
      cp "$file" "$file.backup"

      # Replace links - use different sed syntax for BSD/macOS vs GNU sed
      if sed --version &>/dev/null 2>&1; then
        # GNU sed
        sed -E -i "s@(github.com|githubusercontent.com)/$old_repo/$old_name@\\1/$new_owner/$new_repo@g" "$file"
      else
        # BSD sed (macOS)
        sed -E -i '' "s@(github.com|githubusercontent.com)/$old_repo/$old_name@\\1/$new_owner/$new_repo@g" "$file"
      fi

      ((files_updated++))
      print_success "Updated $file ($count links)"
    fi
  done < <(find "$search_path" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.func" -o -name "*.json" \) -not -path "*/.git/*" 2>/dev/null | xargs grep -E -l "(github.com|githubusercontent.com)/$old_repo/$old_name" 2>/dev/null)

  return $files_updated
}

# Create user git config setup info
create_git_setup_info() {
  local username="$1"

  cat >.git-setup-info <<'EOF'
# Git Configuration for ProxmoxVE Development

## Recommended Git Configuration

### Set up remotes for easy syncing with upstream:

```bash
# View your current remotes
git remote -v

# If you don't have 'upstream' configured, add it:
git remote add upstream https://github.com/community-scripts/ProxmoxVE.git

# Verify both remotes exist:
git remote -v
# Should show:
# origin     https://github.com/YOUR_USERNAME/ProxmoxVE.git (fetch)
# origin     https://github.com/YOUR_USERNAME/ProxmoxVE.git (push)
# upstream   https://github.com/community-scripts/ProxmoxVE.git (fetch)
# upstream   https://github.com/community-scripts/ProxmoxVE.git (push)
```

### Configure Git User (if not done globally)

```bash
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Or configure globally:
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Useful Git Workflows

**Keep your fork up-to-date:**
```bash
git fetch upstream
git rebase upstream/main
git push origin main
```

**Create feature branch:**
```bash
git checkout -b feature/my-awesome-app
# Make changes...
git commit -m "feat: add my awesome app"
git push origin feature/my-awesome-app
```

**Pull latest from upstream:**
```bash
git fetch upstream
git merge upstream/main
```

---

For more help, see: docs/contribution/README.md
EOF

  print_success "Created .git-setup-info file"
}

################################################################################
# MAIN LOGIC
################################################################################

print_header

# Parse command line arguments
if [[ $# -gt 0 ]]; then
  # Check for --full flag
  if [[ "$1" == "--full" ]]; then
    UPDATE_ALL=true
    shift # Remove --full from arguments
  fi

  # Process remaining arguments
  if [[ $# -gt 0 ]]; then
    USERNAME="$1"
    AUTO_DETECT=false

    if [[ $# -gt 1 ]]; then
      REPO_NAME="$2"
    fi
  fi
fi

# Try auto-detection
if [[ -z "$USERNAME" ]]; then
  if username=$(detect_username); then
    USERNAME="$username"
    print_success "Detected GitHub username: $USERNAME"
  else
    print_error "Could not auto-detect GitHub username from git config"
    echo -e "${YELLOW}Please run:${NC}"
    echo "  ./setup-fork.sh YOUR_USERNAME"
    exit 1
  fi
fi

# Auto-detect repo name if needed
if repo_name=$(detect_repo_name); then
  REPO_NAME="$repo_name"
  if [[ "$REPO_NAME" != "ProxmoxVE" ]]; then
    print_info "Detected custom repo name: $REPO_NAME"
  else
    print_success "Using default repo name: ProxmoxVE"
  fi
fi

# Validate inputs
if [[ -z "$USERNAME" ]]; then
  print_error "Username cannot be empty"
  exit 1
fi

if [[ -z "$REPO_NAME" ]]; then
  print_error "Repository name cannot be empty"
  exit 1
fi

# Show what we'll do
echo -e "${BLUE}Configuration Summary:${NC}"
echo "  Repository URL: https://github.com/$USERNAME/$REPO_NAME"
if [[ "$UPDATE_ALL" == "true" ]]; then
  echo "  Files to update: ALL files (ct/, install/, vm/, misc/, docs/, etc.)"
else
  echo "  Files to update: misc/ directory only (core functions)"
fi
echo ""

# Ask for confirmation
if ! confirm "Apply these changes?"; then
  print_warning "Setup cancelled"
  exit 0
fi

echo ""

# Update all links
if update_links "$USERNAME" "$REPO_NAME"; then
  links_changed=$?
  print_success "Updated $links_changed files"
else
  print_warning "No links needed updating or some files not found"
fi

# Create git setup info file
create_git_setup_info "$USERNAME"

# Final summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC} Fork Setup Complete!                                    ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_success "All documentation links updated to point to your fork"
print_info "Your fork: https://github.com/$USERNAME/$REPO_NAME"
print_info "Upstream: https://github.com/community-scripts/ProxmoxVE"
echo ""

echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Review the changes: git diff"
echo "  2. Check .git-setup-info for recommended git workflow"
echo "  3. Start developing: git checkout -b feature/my-app"
echo "  4. Read: docs/contribution/README.md"
echo ""

print_success "Happy contributing! 🚀"
