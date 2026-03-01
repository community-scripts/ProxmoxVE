# 🎯 **ProxmoxVE Contribution Guide**

**Everything you need to know to contribute to ProxmoxVE**

> **Last Updated**: December 2025
> **Difficulty**: Beginner → Advanced
> **Time to Setup**: 15 minutes
> **Time to Contribute**: 1-3 hours

---

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Development Setup](#development-setup)
- [Creating New Applications](#creating-new-applications)
- [Updating Existing Applications](#updating-existing-applications)
- [Code Standards](#code-standards)
- [Testing Your Changes](#testing-your-changes)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## Quick Start

### Setup Your Fork (First Time Only)

```bash
# 1. Fork the repository on GitHub
# Visit: https://github.com/community-scripts/ProxmoxVE
# Click: Fork (top right)

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/ProxmoxVE.git
cd ProxmoxVE

# 3. Run fork setup script (automatically configures everything)
bash docs/contribution/setup-fork.sh --full
# --full updates ct/, install/, vm/, docs/, misc/ links for fork testing

# 4. Read the git workflow tips
cat .git-setup-info
```

### 60 Seconds to First Contribution

```bash
# 1. Create feature branch
git checkout -b add/my-awesome-app

# 2. Create application scripts from templates
cp docs/contribution/templates_ct/AppName.sh ct/myapp.sh
cp docs/contribution/templates_install/AppName-install.sh install/myapp-install.sh
cp docs/contribution/templates_json/AppName.json frontend/public/json/myapp.json

# 3. Edit your scripts
nano ct/myapp.sh
nano install/myapp-install.sh
nano frontend/public/json/myapp.json

# 4. Commit and push to your fork
git add ct/myapp.sh install/myapp-install.sh frontend/public/json/myapp.json
git commit -m "feat: add MyApp container and install scripts"
git push origin add/my-awesome-app

# 5. Test via curl from your fork (GitHub may take 10-30 seconds)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"

# 6. Use cherry-pick to submit only your files (see Cherry-Pick section)
# DO NOT submit the 600+ files modified by setup-fork.sh!

# 7. Open Pull Request on GitHub
# Create PR from: your-fork/add/my-awesome-app → community-scripts/ProxmoxVE/main
```

**💡 Tip**: See `../FORK_SETUP.md` for detailed fork setup and troubleshooting

---

## Repository Structure

### Top-Level Organization

```
ProxmoxVE/
├── ct/                          # 🏗️  Container creation scripts (host-side)
│   ├── pihole.sh
│   ├── docker.sh
│   └── ... (40+ applications)
│
├── install/                     # 🛠️  Installation scripts (container-side)
│   ├── pihole-install.sh
│   ├── docker-install.sh
│   └── ... (40+ applications)
│
├── vm/                          # 💾 VM creation scripts
│   ├── ubuntu2404-vm.sh
│   ├── debian-vm.sh
│   └── ... (15+ operating systems)
│
├── misc/                        # 📦 Shared function libraries
│   ├── build.func               # Main orchestrator (3800+ lines)
│   ├── core.func                # UI/utilities
│   ├── error_handler.func       # Error management
│   ├── tools.func               # Tool installation
│   ├── install.func             # Container setup
│   ├── cloud-init.func          # VM configuration
│   ├── api.func                 # Telemetry
│   ├── alpine-install.func      # Alpine-specific
│   └── alpine-tools.func        # Alpine tools
│
├── docs/                        # 📚 Documentation
│   ├── ct/DETAILED_GUIDE.md     # Container script guide
│   ├── install/DETAILED_GUIDE.md # Install script guide
│   └── contribution/README.md   # Contribution overview
│
├── tools/                       # 🔧 Proxmox management tools
│   └── pve/
│
└── README.md                    # Project overview
```

### Naming Conventions

```
Container Script:      ct/AppName.sh
Installation Script:   install/appname-install.sh
Defaults:             defaults/appname.vars
Update Script:        /usr/bin/update (inside container)

Examples:
  ct/pihole.sh                → install/pihole-install.sh
  ct/docker.sh                → install/docker-install.sh
  ct/nextcloud-vm.sh          → install/nextcloud-vm-install.sh
```

**Rules**:

- Container script name: **Title Case** (PiHole, Docker, NextCloud)
- Install script name: **lowercase** with **hyphens** (pihole-install, docker-install)
- Must match: `ct/AppName.sh` ↔ `install/appname-install.sh`
- Directory names: lowercase (always)
- Variable names: lowercase (except APP constant)

---

## Development Setup

### Prerequisites

1. **Proxmox VE 8.0+** with at least:
   - 4 CPU cores
   - 8 GB RAM
   - 50 GB disk space
   - Ubuntu 20.04 / Debian 11+ on host

2. **Git** installed

   ```bash
   apt-get install -y git
   ```

3. **Text Editor** (VS Code recommended)
   ```bash
   # VS Code extensions:
   # - Bash IDE
   # - Shellcheck
   # - Markdown All in One
   ```

### Local Development Workflow

#### Option A: Development Fork (Recommended)

```bash
# 1. Fork on GitHub (one-time)
# Visit: https://github.com/community-scripts/ProxmoxVE
# Click: Fork

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/ProxmoxVE.git
cd ProxmoxVE

# 3. Add upstream remote for updates
git remote add upstream https://github.com/community-scripts/ProxmoxVE.git

# 4. Create feature branch
git checkout -b feat/add-myapp

# 5. Make changes
# ... edit files ...

# 6. Keep fork updated
git fetch upstream
git rebase upstream/main

# 7. Push and open PR
git push origin feat/add-myapp
```

#### Option B: Testing on a Proxmox Host (still via curl)

```bash
# 1. SSH into Proxmox host
ssh root@192.168.1.100

# 2. Test via curl from your fork (CT script only)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"
# ⏱️ Wait 10-30 seconds after pushing - GitHub takes time to update
```

> **Note:** Do not edit URLs manually or run install scripts directly. The CT script calls the install script inside the container.

#### Option C: Using Curl (Recommended for Real Testing)

```bash
# Always test via curl from your fork (GitHub takes 10-30 seconds after push)
git push origin feature/myapp
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"
# This tests the actual GitHub URLs, not local files
```

#### Option D: Static Checks (Without Proxmox)

```bash
# You can validate syntax and linting locally (limited)
# Note: This does NOT replace real Proxmox testing

# Run ShellCheck
shellcheck ct/myapp.sh
shellcheck install/myapp-install.sh

# Syntax check
bash -n ct/myapp.sh
bash -n install/myapp-install.sh
```

---

## Creating New Applications

### Step 1: Choose Your Template

**For Simple Web Apps** (Node.js, Python, PHP):

```bash
cp ct/example.sh ct/myapp.sh
cp install/example-install.sh install/myapp-install.sh
```

**For Database Apps** (PostgreSQL, MariaDB, MongoDB):

Use the standard templates and the database helpers from `tools.func` (no Docker).

**For Alpine Linux Apps** (lightweight):

```bash
# Use ct/alpine.sh as reference
# Edit install script to use Alpine packages (apk not apt)
```

### Step 2: Update Container Script

**File**: `ct/myapp.sh`

```bash
#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/misc/build.func)

# Update these:
APP="MyAwesomeApp"                    # Display name
var_tags="category;tag2;tag3"         # Max 3-4 tags
var_cpu="2"                          # Realistic CPU cores
var_ram="2048"                       # Min RAM needed (MB)
var_disk="10"                        # Min disk (GB)
var_os="debian"                      # OS type
var_version="12"                     # OS version
var_unprivileged="1"                 # Security (1=unprivileged)

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/myapp ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "myapp" "owner/repo"; then
    msg_info "Stopping Service"
    systemctl stop myapp
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "myapp" "owner/repo" "tarball" "latest" "/opt/myapp"

    # ... update logic (migrations, rebuilds, etc.) ...

    msg_info "Starting Service"
    systemctl start myapp
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:PORT${CL}"
```

**Checklist**:

- [ ] APP variable matches filename
- [ ] var_tags semicolon-separated (no spaces)
- [ ] Realistic CPU/RAM/disk values
- [ ] update_script() implemented
- [ ] Correct OS and version
- [ ] Success message with access URL

### Step 3: Update Installation Script

**File**: `install/myapp-install.sh`

```bash
#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: YourUsername
# License: MIT
# Source: https://github.com/example/myapp

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "myapp" "owner/repo" "tarball" "latest" "/opt/myapp"

motd_ssh
customize
cleanup_lxc
```

**Checklist**:

- [ ] Functions loaded from `$FUNCTIONS_FILE_PATH`
- [ ] All installation phases present (deps, tools, app, config, cleanup)
- [ ] Using `$STD` for output suppression
- [ ] Version file saved
- [ ] Final cleanup with `cleanup_lxc`
- [ ] No hardcoded versions (use GitHub API)

### Step 4: Create ASCII Header (Optional)

**File**: `ct/headers/myapp`

```
╔═══════════════════════════════════════╗
║                                       ║
║          🎉 MyAwesomeApp 🎉          ║
║                                       ║
║  Your app is being installed...       ║
║                                       ║
╚═══════════════════════════════════════╝
```

Save in: `ct/headers/myapp` (no extension)

### Step 5: Create Defaults File (Optional)

**File**: `defaults/myapp.vars`

```bash
# Default configuration for MyAwesomeApp
var_cpu=4
var_ram=4096
var_disk=15
var_hostname=myapp-container
var_timezone=UTC
```

---

## Updating Existing Applications

### Step 1: Identify What Changed

```bash
# Check logs or GitHub releases
curl -fsSL https://api.github.com/repos/app/repo/releases/latest | jq '.'

# Review breaking changes
# Update dependencies if needed
```

### Step 2: Update Installation Script

```bash
# Edit: install/existingapp-install.sh

# 1. Update version (if hardcoded)
RELEASE="2.0.0"

# 2. Update package dependencies (if any changed)
$STD apt-get install -y newdependency

# 3. Update configuration (if format changed)
# Update sed replacements or config files

# 4. Test thoroughly before committing
```

### Step 3: The Standard Update Pattern

The `update_script()` function in `ct/appname.sh` should follow a robust pattern:

1. **Check for updates**: Use `check_for_gh_release` to skip logic if no new version exists.
2. **Stop services**: Stop all relevant services (`systemctl stop appname`).
3. **Backup existing installation**: Move the old folder (e.g., `mv /opt/app /opt/app_bak`).
4. **Deploy new version**: Use `CLEAN_INSTALL=1 fetch_and_deploy_gh_release`.
5. **Restore configuration**: Copy `.env` or config files back from the backup.
6. **Rebuild/Migrate**: Run `npm install`, `composer install`, or DB migrations.
7. **Start services**: Restart services and cleanup the backup.

**Example from `ct/bookstack.sh`**:
```bash
function update_script() {
  if check_for_gh_release "bookstack" "BookStackApp/BookStack"; then
    msg_info "Stopping Services"
    systemctl stop apache2
    
    msg_info "Backing up data"
    mv /opt/bookstack /opt/bookstack-backup
    
    fetch_and_deploy_gh_release "bookstack" "BookStackApp/BookStack" "tarball"
    
    msg_info "Restoring backup"
    cp /opt/bookstack-backup/.env /opt/bookstack/.env
    # ... restore uploads ...
    
    msg_info "Configuring"
    cd /opt/bookstack
    $STD composer install --no-dev
    $STD php artisan migrate --force
    
    systemctl start apache2
    rm -rf /opt/bookstack-backup
    msg_ok "Updated successfully!"
  fi
}
```

---

## Code Standards

### Bash Style Guide

#### Variable Naming

```bash
# ✅ Good
APP="MyApp"                 # Constants (UPPERCASE)
var_cpu="2"                # Configuration (var_*)
container_id="100"         # Local variables (lowercase)
DB_PASSWORD="secret"       # Environment-like (UPPERCASE)

# ❌ Bad
myapp="MyApp"              # Inconsistent
VAR_CPU="2"               # Wrong convention
containerid="100"         # Unclear purpose
```

#### Function Naming

```bash
# ✅ Good
function setup_database() { }       # Descriptive
function check_version() { }        # Verb-noun pattern
function install_dependencies() { } # Clear action

# ❌ Bad
function setup() { }                # Too vague
function db_setup() { }             # Inconsistent pattern
function x() { }                    # Cryptic
```

#### Quoting

```bash
# ✅ Good
echo "${APP}"                       # Always quote variables
if [[ "$var" == "value" ]]; then   # Use [[ ]] for conditionals
echo "Using $var in string"        # Variables in double quotes

# ❌ Bad
echo $APP                          # Unquoted variables
if [ "$var" = "value" ]; then      # Use [[ ]] instead
echo 'Using $var in string'        # Single quotes prevent expansion
```

#### Command Formatting

```bash
# ✅ Good: Multiline for readability
$STD apt-get install -y \
  package1 \
  package2 \
  package3

# ✅ Good: Complex commands with variables
if ! wget -q "https://example.com/${file}"; then
  msg_error "Failed to download"
  exit 1
fi

# ❌ Bad: Too long on one line
$STD apt-get install -y package1 package2 package3 package4 package5 package6

# ❌ Bad: No error checking
wget https://example.com/file
```

#### Error Handling

```bash
# ✅ Good: Check critical commands
if ! some_command; then
  msg_error "Command failed"
  exit 1
fi

# ✅ Good: Use catch_errors for automatic trapping
catch_errors

# ❌ Bad: Silently ignore failures
some_command || true
some_command 2>/dev/null

# ❌ Bad: Unclear what failed
if ! (cmd1 && cmd2 && cmd3); then
  msg_error "Something failed"
fi
```

### Documentation Standards

#### Header Comments

```bash
#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: YourUsername
# Co-Author: AnotherAuthor (for collaborative work)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/app/repo
# Description: Brief description of what this script does
```

#### Inline Comments

```bash
# ✅ Good: Explain WHY, not WHAT
# Use alphanumeric only to avoid shell escaping issues
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)

# ✅ Good: Comment complex logic
# Detect if running Alpine vs Debian for proper package manager
if grep -qi 'alpine' /etc/os-release; then
  PKG_MGR="apk"
else
  PKG_MGR="apt"
fi

# ❌ Bad: Comment obvious code
# Set the variable
var="value"

# ❌ Bad: Outdated comments
# TODO: Fix this (written 2 years ago, not fixed)
```

### File Organization

```bash
#!/usr/bin/env bash                  # [1] Shebang (first line)
# Copyright & Metadata               # [2] Comments
                                     # [3] Blank line
# Load functions                     # [4] Import section
source <(curl -fsSL ...)
                                     # [5] Blank line
# Configuration                      # [6] Variables/Config
APP="MyApp"
var_cpu="2"
                                     # [7] Blank line
# Initialization                     # [8] Setup
header_info "$APP"
variables
color
catch_errors
                                     # [9] Blank line
# Functions                          # [10] Function definitions
function update_script() { }
function custom_setup() { }
                                     # [11] Blank line
# Main execution                     # [12] Script logic
start
build_container
```

---

## Testing Your Changes

### Pre-Submission Testing

#### 1. Syntax Check

```bash
# Verify bash syntax
bash -n ct/myapp.sh
bash -n install/myapp-install.sh

# If no output: ✅ Syntax is valid
# If error output: ❌ Fix syntax before submitting
```

#### 2. ShellCheck Static Analysis

```bash
# Install ShellCheck
apt-get install -y shellcheck

# Check scripts
shellcheck ct/myapp.sh
shellcheck install/myapp-install.sh

# Review warnings and fix if applicable
# Some warnings can be intentional (use # shellcheck disable=...)
```

#### 3. Real Proxmox Testing

```bash
# Best: Test on actual Proxmox system

# 1. SSH into Proxmox host
ssh root@YOUR_PROXMOX_IP

# 2. Test via curl from your fork (CT script only)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"
# ⏱️ Wait 10-30 seconds after pushing - GitHub takes time to update

# 3. Test interaction:
#    - Select installation mode
#    - Confirm settings
#    - Monitor installation

# 4. Verify container created
pct list | grep myapp

# 5. Log into container and verify app
pct exec 100 bash
```

#### 4. Edge Case Testing

```bash
# Test with different settings:

# Test 1: Advanced (19-step) installation
# When prompted: Select "2" for Advanced

# Test 2: User Defaults
# Before running: Create ~/.community-scripts/default.vars
# When prompted: Select "3" for User Defaults

# Test 3: Error handling
# Simulate network outage (block internet)
# Verify script handles gracefully

# Test 4: Update function
# Create initial container (via curl from fork)
# Wait for new release
# Test update: bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"
# Verify it detects and applies update
```

### Testing Checklist

Before submitting PR:

```bash
# Code quality
- [ ] Syntax: bash -n passes
- [ ] ShellCheck: No critical warnings
- [ ] Naming: Follows conventions
- [ ] Formatting: Consistent indentation

# Functionality
- [ ] Container creation: Successful
- [ ] Installation: Completes without errors
- [ ] Access URL: Works and app responds
- [ ] Update function: Detects new versions
- [ ] Cleanup: No temporary files left

# Documentation
- [ ] Copyright header present
- [ ] App name matches filenames
- [ ] Default values realistic
- [ ] Success message clear and helpful

# Compatibility
- [ ] Works on Debian 12
- [ ] Works on Ubuntu 22.04
- [ ] (Optional) Works on Alpine 3.20
```

---

## Submitting a Pull Request

### Step 1: Prepare Your Branch

```bash
# Update with latest changes
git fetch upstream
git rebase upstream/main

# If conflicts occur:
git rebase --abort
# Resolve conflicts manually then:
git add .
git rebase --continue
```

### Step 2: Push Your Changes

```bash
git push origin feat/add-myapp

# If already pushed:
git push origin feat/add-myapp --force-with-lease
```

### Step 3: Create Pull Request on GitHub

**Visit**: https://github.com/community-scripts/ProxmoxVE/pulls

**Click**: "New Pull Request"

**Select**: `community-scripts:main` ← `YOUR_USERNAME:feat/myapp`

### Step 4: Fill PR Description

Use this template:

```markdown
## Description

Brief description of what this PR adds/fixes

## Type of Change

- [ ] New application (ct/AppName.sh + install/appname-install.sh)
- [ ] Update existing application
- [ ] Bug fix
- [ ] Documentation update
- [ ] Other: **\_\_\_**

## Testing

- [ ] Tested on Proxmox VE 8.x
- [ ] Container creation successful
- [ ] Application installation successful
- [ ] Application is accessible at URL
- [ ] Update function works (if applicable)
- [ ] No temporary files left after installation

## Application Details (for new apps only)

- **App Name**: MyApp
- **Source**: https://github.com/app/repo
- **Default OS**: Debian 12
- **Recommended Resources**: 2 CPU, 2GB RAM, 10GB Disk
- **Tags**: category;tag2;tag3
- **Access URL**: http://IP:PORT/path

## Checklist

- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have tested the script via curl from my fork (after git push)
- [ ] GitHub had time to update (waited 10-30 seconds)
- [ ] ShellCheck shows no critical warnings
- [ ] Documentation is accurate and complete
- [ ] I have added/updated relevant documentation
```

### Step 5: Respond to Review Comments

**Maintainers may request changes**:

- Fix syntax/style issues
- Add better error handling
- Optimize resource usage
- Update documentation

**To address feedback**:

```bash
# Make requested changes
git add .
git commit -m "Address review feedback: ..."
git push origin feat/add-myapp

# PR automatically updates!
# No need to create new PR
```

### Step 6: Celebrate! 🎉

Once merged, your contribution will be part of ProxmoxVE and available to all users!

---

## Troubleshooting

### "Repository not found" when cloning

```bash
# Check your fork exists
# Visit: https://github.com/YOUR_USERNAME/ProxmoxVE

# If not there: Click "Fork" on original repo first
```

### "Permission denied" when pushing

```bash
# Setup SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub  # Copy this

# Add to GitHub: Settings → SSH Keys → New Key

# Or use HTTPS with token:
git remote set-url origin https://YOUR_TOKEN@github.com/YOUR_USERNAME/ProxmoxVE.git
```

### Script syntax errors

```bash
# Use ShellCheck to identify issues
shellcheck install/myapp-install.sh

# Common issues:
# - Unmatched quotes: "string' or 'string"
# - Missing semicolons before then: if [...]; then
# - Wrong quoting: echo $VAR instead of echo "${VAR}"
```

### Container creation fails immediately

```bash
# 1. Check Proxmox resources
free -h              # Check RAM
df -h                # Check disk space
pct list            # Check CTID availability

# 2. Check script URL
# Make sure curl -s in script points to your fork

# 3. Review errors
# Run with verbose: bash -x ct/myapp.sh
```

### App not accessible after creation

```bash
# 1. Verify container running
pct list
pct status CTID

# 2. Check if service running inside
pct exec CTID systemctl status myapp

# 3. Check firewall
# Proxmox host: iptables -L
# Container: iptables -L

# 4. Verify listening port
pct exec CTID netstat -tlnp | grep LISTEN
```

---

## FAQ

### Q: Do I need to be a Bash expert?

**A**: No! The codebase has many examples you can copy. Most contributions are straightforward script creation following the established patterns.

### Q: Can I add a new application that's not open source?

**A**: No. ProxmoxVE focuses on open-source applications (GPL, MIT, Apache, etc.). Closed-source applications won't be accepted.

### Q: How long until my PR is reviewed?

**A**: Maintainers are volunteers. Reviews typically happen within 1-2 weeks. Complex changes may take longer.

### Q: Can I test without a Proxmox system?

**A**: Partially. You can verify syntax and ShellCheck compliance locally, but real container testing requires Proxmox. Consider using:

- Proxmox in a VM (VirtualBox/KVM)
- Test instances on Hetzner/DigitalOcean
- Ask maintainers to test for you

### Q: My update function is very complex - is that OK?

**A**: Yes! Update functions can be complex if needed. Just ensure:

- Backup user data before updating
- Restore user data after update
- Test thoroughly before submitting
- Add clear comments explaining logic

### Q: Can I add new dependencies to build.func?

**A**: Generally no. build.func is the orchestrator and should remain stable. New functions should go in:

- `tools.func` - Tool installation
- `core.func` - Utility functions
- `install.func` - Container setup

Ask in an issue first if you're unsure.

### Q: What if the application has many configuration options?

**A**: You have options:

**Option 1**: Use Advanced mode (19-step wizard)

```bash
# Extend advanced_settings() if app needs special vars
```

**Option 2**: Create custom setup menu

```bash
function custom_config() {
  OPTION=$(whiptail --inputbox "Enter database name:" 8 60)
  # ... use $OPTION in installation
}
```

**Option 3**: Leave as defaults + documentation

```bash
# In success message:
echo "Edit /opt/myapp/config.json to customize settings"
```

### Q: Can I contribute Windows/macOS/ARM support?

**A**:

- **Windows**: Not planned (ProxmoxVE is Linux/Proxmox focused)
- **macOS**: Can contribute Docker-based alternatives
- **ARM**: Yes! Many apps work on ARM. Add to vm/pimox-\*.sh scripts

---

## Getting Help

### Resources

- **Documentation**: `/docs` directory and wikis
- **Function Reference**: `/misc/*.md` wiki files
- **Examples**: Look at similar applications in `/ct` and `/install`
- **GitHub Issues**: https://github.com/community-scripts/ProxmoxVE/issues
- **Discussions**: https://github.com/community-scripts/ProxmoxVE/discussions

### Ask Questions

1. **Check existing issues** - Your question may be answered
2. **Search documentation** - See `/docs` and `/misc/*.md`
3. **Ask in Discussions** - For general questions
4. **Open an Issue** - For bugs or specific problems

### Report Bugs

When reporting bugs, include:

- Which application
- What happened (error message)
- What you expected
- Your Proxmox version
- Container OS and version

Example:

```
Title: pihole-install.sh fails on Alpine 3.20

Description:
Installation fails with error: "PHP-FPM not found"

Expected:
PiHole should install successfully

Environment:
- Proxmox VE 8.2
- Alpine 3.20
- Container CTID 110

Error Output:
[ERROR] in line 42: exit code 127: while executing command php-fpm --start
```

---

## Contribution Statistics

**ProxmoxVE by the Numbers**:

- 🎯 40+ applications supported
- 👥 100+ contributors
- 📊 10,000+ GitHub stars
- 🚀 50+ releases
- 📈 100,000+ downloads/month

**Your contribution makes a difference!**

---

## Code of Conduct

By contributing, you agree to:

- ✅ Be respectful and inclusive
- ✅ Follow the style guidelines
- ✅ Test your changes thoroughly
- ✅ Provide clear commit messages
- ✅ Respond to review feedback

---

**Ready to contribute?** Start with the [Quick Start](#quick-start) section!

**Questions?** Open an issue or start a discussion on GitHub.

**Thank you for your contribution!** 🙏
