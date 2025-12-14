# Configuration & Defaults System - User Guide

> **Complete Guide to App Defaults and User Defaults**
> 
> *Learn how to configure, save, and reuse your installation settings*

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Understanding the Defaults System](#understanding-the-defaults-system)
3. [Installation Modes](#installation-modes)
4. [How to Save Defaults](#how-to-save-defaults)
5. [How to Use Saved Defaults](#how-to-use-saved-defaults)
6. [Managing Your Defaults](#managing-your-defaults)
7. [Advanced Configuration](#advanced-configuration)
8. [Troubleshooting](#troubleshooting)

---

## Quick Start

### 30-Second Setup

```bash
# 1. Run any container installation script
bash pihole-install.sh

# 2. When prompted, select: "Advanced Settings"
#    (This allows you to customize everything)

# 3. Answer all configuration questions

# 4. At the end, when asked "Save as App Defaults?"
#    Select: YES

# 5. Done! Your settings are now saved
```

**Next Time**: Run the same script again, select **"App Defaults"** and your settings will be applied automatically!

---

## Understanding the Defaults System

### The Three-Tier System

Your installation settings are managed through three layers:

#### 🔷 **Tier 1: Built-in Defaults** (Fallback)
```
These are hardcoded in the scripts
Provide sensible defaults for each application
Example: PiHole uses 2 CPU cores by default
```

#### 🔶 **Tier 2: User Defaults** (Global)
```
Your personal global defaults
Applied to ALL container installations
Location: /usr/local/community-scripts/default.vars
Example: "I always want 4 CPU cores and 2GB RAM"
```

#### 🔴 **Tier 3: App Defaults** (Specific)
```
Application-specific saved settings
Only applied when installing that specific app
Location: /usr/local/community-scripts/defaults/<appname>.vars
Example: "Whenever I install PiHole, use these exact settings"
```

### Priority System

When installing a container, settings are applied in this order:

```
┌─────────────────────────────────────┐
│ 1. Environment Variables (HIGHEST)  │  Set in shell: export var_cpu=8
│    (these override everything)      │
├─────────────────────────────────────┤
│ 2. App Defaults                     │  From: defaults/pihole.vars
│    (app-specific saved settings)    │
├─────────────────────────────────────┤
│ 3. User Defaults                    │  From: default.vars
│    (your global defaults)           │
├─────────────────────────────────────┤
│ 4. Built-in Defaults (LOWEST)       │  Hardcoded in script
│    (failsafe, always available)     │
└─────────────────────────────────────┘
```

**In Plain English**: 
- If you set an environment variable → it wins
- Otherwise, if you have app-specific defaults → use those
- Otherwise, if you have user defaults → use those
- Otherwise, use the hardcoded defaults

---

## Installation Modes

When you run any installation script, you'll be presented with a menu:

### Option 1️⃣ : **Default Settings**

```
Quick installation with standard settings
├─ Best for: First-time users, quick deployments
├─ What happens:
│  1. Script uses built-in defaults
│  2. Container created immediately
│  3. No questions asked
└─ Time: ~2 minutes
```

**When to use**: You want a standard installation, don't need customization

---

### Option 2️⃣ : **Advanced Settings**

```
Full customization with 19 configuration steps
├─ Best for: Power users, custom requirements
├─ What happens:
│  1. Script asks for EVERY setting
│  2. You control: CPU, RAM, Disk, Network, SSH, etc.
│  3. Shows summary before creating
│  4. Offers to save as App Defaults
└─ Time: ~5-10 minutes
```

**When to use**: You want full control over the configuration

**Available Settings**:
- CPU cores, RAM amount, Disk size
- Container name, network settings
- SSH access, API access, Features
- Password, SSH keys, Tags

---

### Option 3️⃣ : **User Defaults**

```
Use your saved global defaults
├─ Best for: Consistent deployments across many containers
├─ Requires: You've previously saved User Defaults
├─ What happens:
│  1. Loads settings from: /usr/local/community-scripts/default.vars
│  2. Shows you the loaded settings
│  3. Creates container immediately
└─ Time: ~2 minutes
```

**When to use**: You have preferred defaults you want to use for every app

---

### Option 4️⃣ : **App Defaults** (if available)

```
Use previously saved app-specific defaults
├─ Best for: Repeating the same configuration multiple times
├─ Requires: You've previously saved App Defaults for this app
├─ What happens:
│  1. Loads settings from: /usr/local/community-scripts/defaults/<app>.vars
│  2. Shows you the loaded settings
│  3. Creates container immediately
└─ Time: ~2 minutes
```

**When to use**: You've installed this app before and want identical settings

---

### Option 5️⃣ : **Settings Menu**

```
Manage your saved configurations
├─ Functions:
│  • View current settings
│  • Edit storage selections
│  • Manage defaults location
│  • See what's currently configured
└─ Time: ~1 minute
```

**When to use**: You want to review or modify saved settings

---

## How to Save Defaults

### Method 1: Save While Installing

This is the easiest way:

#### Step-by-Step: Create App Defaults

```bash
# 1. Run the installation script
bash pihole-install.sh

# 2. Choose installation mode
#    ┌─────────────────────────┐
#    │ Select installation mode:│
#    │ 1) Default Settings     │
#    │ 2) Advanced Settings    │
#    │ 3) User Defaults        │
#    │ 4) App Defaults         │
#    │ 5) Settings Menu        │
#    └─────────────────────────┘
#
#    Enter: 2 (Advanced Settings)

# 3. Answer all configuration questions
#    • Container name? → my-pihole
#    • CPU cores? → 4
#    • RAM amount? → 2048
#    • Disk size? → 20
#    • SSH access? → yes
#    ... (more options)

# 4. Review summary (shown before creation)
#    ✓ Confirm to proceed

# 5. After creation completes, you'll see:
#    ┌──────────────────────────────────┐
#    │ Save as App Defaults for PiHole? │
#    │ (Yes/No)                         │
#    └──────────────────────────────────┘
#
#    Select: Yes

# 6. Done! Settings saved to:
#    /usr/local/community-scripts/defaults/pihole.vars
```

#### Step-by-Step: Create User Defaults

```bash
# Same as App Defaults, but:
# When you select "Advanced Settings"
# FIRST app you run with this selection will offer
# to save as "User Defaults" additionally

# This saves to: /usr/local/community-scripts/default.vars
```

---

### Method 2: Manual File Creation

For advanced users who want to create defaults without running installation:

```bash
# Create User Defaults manually
sudo tee /usr/local/community-scripts/default.vars > /dev/null << 'EOF'
# Global User Defaults
var_cpu=4
var_ram=2048
var_disk=20
var_unprivileged=1
var_brg=vmbr0
var_gateway=192.168.1.1
var_timezone=Europe/Berlin
var_ssh=yes
var_container_storage=local
var_template_storage=local
EOF

# Create App Defaults manually
sudo tee /usr/local/community-scripts/defaults/pihole.vars > /dev/null << 'EOF'
# App-specific defaults for PiHole
var_unprivileged=1
var_cpu=2
var_ram=1024
var_disk=10
var_brg=vmbr0
var_gateway=192.168.1.1
var_hostname=pihole
var_container_storage=local
var_template_storage=local
EOF
```

---

### Method 3: Using Environment Variables

Set defaults via environment before running:

```bash
# Set as environment variables
export var_cpu=4
export var_ram=2048
export var_disk=20
export var_hostname=my-container

# Run installation
bash pihole-install.sh

# These settings will be used
# (Can still be overridden by saved defaults)
```

---

## How to Use Saved Defaults

### Using User Defaults

```bash
# 1. Run any installation script
bash pihole-install.sh

# 2. When asked for mode, select:
#    Option: 3 (User Defaults)

# 3. Your settings from default.vars are applied
# 4. Container created with your saved settings
```

### Using App Defaults

```bash
# 1. Run the app you configured before
bash pihole-install.sh

# 2. When asked for mode, select:
#    Option: 4 (App Defaults)

# 3. Your settings from defaults/pihole.vars are applied
# 4. Container created with exact same settings
```

### Overriding Saved Defaults

```bash
# Even if you have defaults saved,
# you can override them with environment variables

export var_cpu=8  # Override saved defaults
export var_hostname=custom-name

bash pihole-install.sh
# Installation will use these values instead of saved defaults
```

---

## Managing Your Defaults

### View Your Settings

#### View User Defaults
```bash
cat /usr/local/community-scripts/default.vars
```

#### View App Defaults
```bash
cat /usr/local/community-scripts/defaults/pihole.vars
```

#### List All Saved App Defaults
```bash
ls -la /usr/local/community-scripts/defaults/
```

### Edit Your Settings

#### Edit User Defaults
```bash
sudo nano /usr/local/community-scripts/default.vars
```

#### Edit App Defaults
```bash
sudo nano /usr/local/community-scripts/defaults/pihole.vars
```

### Update Existing Defaults

```bash
# Run installation again with your app
bash pihole-install.sh

# Select: Advanced Settings
# Make desired changes
# At end, when asked to save:
#   "Defaults already exist, Update?"
#   Select: Yes

# Your saved defaults are updated
```

### Delete Defaults

#### Delete User Defaults
```bash
sudo rm /usr/local/community-scripts/default.vars
```

#### Delete App Defaults
```bash
sudo rm /usr/local/community-scripts/defaults/pihole.vars
```

#### Delete All App Defaults
```bash
sudo rm /usr/local/community-scripts/defaults/*
```

---

## Advanced Configuration

### Available Variables

All configurable variables start with `var_`:

#### Resource Allocation
```bash
var_cpu=4              # CPU cores
var_ram=2048           # RAM in MB
var_disk=20            # Disk in GB
var_unprivileged=1     # 0=privileged, 1=unprivileged
```

#### Network
```bash
var_brg=vmbr0          # Bridge interface
var_net=veth           # Network driver
var_gateway=192.168.1.1  # Default gateway
var_mtu=1500           # MTU size
var_vlan=100           # VLAN ID
```

#### System
```bash
var_hostname=pihole    # Container name
var_timezone=Europe/Berlin  # Timezone
var_pw=SecurePass123   # Root password
var_tags=dns,pihole    # Tags for organization
var_verbose=yes        # Enable verbose output
```

#### Security & Access
```bash
var_ssh=yes            # Enable SSH
var_ssh_authorized_key="ssh-rsa AA..." # SSH public key
var_protection=1       # Enable protection flag
```

#### Features
```bash
var_fuse=1             # FUSE filesystem support
var_tun=1              # TUN device support
var_nesting=1          # Nesting (Docker in LXC)
var_keyctl=1           # Keyctl syscall
var_mknod=1            # Device node creation
```

#### Storage
```bash
var_container_storage=local    # Where to store container
var_template_storage=local     # Where to store templates
```

### Example Configuration Files

#### Gaming Server Defaults
```bash
# High performance for gaming containers
var_cpu=8
var_ram=4096
var_disk=50
var_unprivileged=0
var_fuse=1
var_nesting=1
var_tags=gaming
```

#### Development Server
```bash
# Development with Docker support
var_cpu=4
var_ram=2048
var_disk=30
var_unprivileged=1
var_nesting=1
var_ssh=yes
var_tags=development
```

#### IoT/Monitoring
```bash
# Low-resource, always-on containers
var_cpu=2
var_ram=512
var_disk=10
var_unprivileged=1
var_nesting=0
var_fuse=0
var_tun=0
var_tags=iot,monitoring
```

---

## Troubleshooting

### "App Defaults not available" Message

**Problem**: You want to use App Defaults, but option says they're not available

**Solution**:
1. You haven't created App Defaults yet for this app
2. Run the app with "Advanced Settings"
3. When finished, save as App Defaults
4. Next time, App Defaults will be available

---

### "Settings not being applied"

**Problem**: You saved defaults, but they're not being used

**Checklist**:
```bash
# 1. Verify files exist
ls -la /usr/local/community-scripts/default.vars
ls -la /usr/local/community-scripts/defaults/<app>.vars

# 2. Check file permissions (should be readable)
stat /usr/local/community-scripts/default.vars

# 3. Verify correct mode selected
#    (Make sure you selected "User Defaults" or "App Defaults")

# 4. Check for environment variable override
env | grep var_
#    If you have var_* set in environment,
#    those override your saved defaults
```

---

### "Cannot write to defaults location"

**Problem**: Permission denied when saving defaults

**Solution**:
```bash
# Create the defaults directory if missing
sudo mkdir -p /usr/local/community-scripts/defaults

# Fix permissions
sudo chmod 755 /usr/local/community-scripts
sudo chmod 755 /usr/local/community-scripts/defaults

# Make sure you're running as root
sudo bash pihole-install.sh
```

---

### "Defaults directory doesn't exist"

**Problem**: Script can't find where to save defaults

**Solution**:
```bash
# Create the directory
sudo mkdir -p /usr/local/community-scripts/defaults

# Verify
ls -la /usr/local/community-scripts/
```

---

### Settings seem random or wrong

**Problem**: Container gets different settings than expected

**Possible Causes & Solutions**:

```bash
# 1. Check if environment variables are set
env | grep var_
# If you see var_* entries, those override your defaults
# Clear them: unset var_cpu var_ram (etc)

# 2. Verify correct defaults are in files
cat /usr/local/community-scripts/default.vars
cat /usr/local/community-scripts/defaults/pihole.vars

# 3. Check which mode you actually selected
# (Script output shows which defaults were applied)

# 4. Check Proxmox logs for errors
sudo journalctl -u pve-daemon -n 50
```

---

### "Variable not recognized"

**Problem**: You set a variable that doesn't work

**Solution**:
Only certain variables are allowed (security whitelist):

```
Allowed variables (starting with var_):
✓ var_cpu, var_ram, var_disk, var_unprivileged
✓ var_brg, var_gateway, var_mtu, var_vlan, var_net
✓ var_hostname, var_pw, var_timezone
✓ var_ssh, var_ssh_authorized_key
✓ var_fuse, var_tun, var_nesting, var_keyctl
✓ var_container_storage, var_template_storage
✓ var_tags, var_verbose
✓ var_apt_cacher, var_apt_cacher_ip
✓ var_protection, var_mount_fs

✗ Other variables are NOT supported
```

---

## Best Practices

### ✅ Do's

✓ Use **App Defaults** when you want app-specific settings
✓ Use **User Defaults** for your global preferences
✓ Edit defaults files directly with `nano` (safe)
✓ Keep separate App Defaults for each app
✓ Back up your defaults regularly
✓ Use environment variables for temporary overrides

### ❌ Don'ts

✗ Don't use `source` on defaults files (security risk)
✗ Don't put sensitive passwords in defaults (use SSH keys)
✗ Don't modify defaults while installation is running
✗ Don't delete defaults.d while containers are being created
✗ Don't use special characters without escaping

---

## Quick Reference

### Defaults Locations

| Type | Location | Example |
|------|----------|---------|
| User Defaults | `/usr/local/community-scripts/default.vars` | Global settings |
| App Defaults | `/usr/local/community-scripts/defaults/<app>.vars` | PiHole-specific |
| Backup Dir | `/usr/local/community-scripts/defaults/` | All app defaults |

### File Format

```bash
# Comments start with #
var_name=value

# No spaces around =
✓ var_cpu=4
✗ var_cpu = 4

# String values don't need quotes
✓ var_hostname=mycontainer
✓ var_hostname='mycontainer'

# Values with spaces need quotes
✓ var_tags="docker,production,testing"
✗ var_tags=docker,production,testing
```

### Command Reference

```bash
# View defaults
cat /usr/local/community-scripts/default.vars

# Edit defaults
sudo nano /usr/local/community-scripts/default.vars

# List all app defaults
ls /usr/local/community-scripts/defaults/

# Backup your defaults
cp -r /usr/local/community-scripts/defaults/ ~/defaults-backup/

# Set temporary override
export var_cpu=8
bash pihole-install.sh

# Create custom defaults
sudo tee /usr/local/community-scripts/defaults/custom.vars << 'EOF'
var_cpu=4
var_ram=2048
EOF
```

---

## Getting Help

### Need More Information?

- 📖 [Main Documentation](../../docs/)
- 🐛 [Report Issues](https://github.com/community-scripts/ProxmoxVE/issues)
- 💬 [Discussions](https://github.com/community-scripts/ProxmoxVE/discussions)

### Useful Commands

```bash
# Check what variables are available
grep "var_" /path/to/app-install.sh | head -20

# Verify defaults syntax
cat /usr/local/community-scripts/default.vars

# Monitor installation with defaults
bash pihole-install.sh 2>&1 | tee installation.log
```

---

## Document Information

| Field | Value |
|-------|-------|
| Version | 1.0 |
| Last Updated | November 28, 2025 |
| Status | Current |
| License | MIT |

---

**Happy configuring! 🚀**
