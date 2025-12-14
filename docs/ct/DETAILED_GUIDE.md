# 🚀 **Application Container Scripts (ct/AppName.sh)**

**Modern Guide to Creating LXC Container Installation Scripts**

> **Updated**: December 2025
> **Context**: Fully integrated with build.func, advanced_settings wizard, and defaults system
> **Example Used**: `/ct/pihole.sh`, `/ct/docker.sh`

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture & Flow](#architecture--flow)
- [File Structure](#file-structure)
- [Complete Script Template](#complete-script-template)
- [Function Reference](#function-reference)
- [Advanced Features](#advanced-features)
- [Real Examples](#real-examples)
- [Troubleshooting](#troubleshooting)
- [Contribution Checklist](#contribution-checklist)

---

## Overview

### Purpose

Container scripts (`ct/AppName.sh`) are **entry points for creating LXC containers** with specific applications pre-installed. They:

1. Define container defaults (CPU, RAM, disk, OS)
2. Call the main build orchestrator (`build.func`)
3. Implement application-specific update mechanisms
4. Provide user-facing success messages

### Execution Context

```
Proxmox Host
    ↓
ct/AppName.sh sourced (runs as root on host)
    ↓
build.func: Creates LXC container + runs install script inside
    ↓
install/AppName-install.sh (runs inside container)
    ↓
Container ready with app installed
```

### Key Integration Points

- **build.func** - Main orchestrator (container creation, storage, variable management)
- **install.func** - Container-specific setup (OS update, package management)
- **tools.func** - Tool installation helpers (repositories, GitHub releases)
- **core.func** - UI/messaging functions (colors, spinners, validation)
- **error_handler.func** - Error handling and signal management

---

## Architecture & Flow

### Container Creation Flow

```
START: bash ct/pihole.sh
  ↓
[1] Set APP, var_*, defaults
  ↓
[2] header_info() → Display ASCII art
  ↓
[3] variables() → Parse arguments & load build.func
  ↓
[4] color() → Setup ANSI codes
  ↓
[5] catch_errors() → Setup trap handlers
  ↓
[6] install_script() → Show mode menu (5 options)
  ↓
  ├─ INSTALL_MODE="0" (Default)
  ├─ INSTALL_MODE="1" (Advanced - 19-step wizard)
  ├─ INSTALL_MODE="2" (User Defaults)
  ├─ INSTALL_MODE="3" (App Defaults)
  └─ INSTALL_MODE="4" (Settings Menu)
  ↓
[7] advanced_settings() → Collect user configuration (if mode=1)
  ↓
[8] start() → Confirm or re-edit settings
  ↓
[9] build_container() → Create LXC + execute install script
  ↓
[10] description() → Set container description
  ↓
[11] SUCCESS → Display access URL
  ↓
END
```

### Default Values Precedence

```
Priority 1 (Highest): Environment Variables (var_cpu, var_ram, etc.)
Priority 2: App-Specific Defaults (/defaults/AppName.vars)
Priority 3: User Global Defaults (/default.vars)
Priority 4 (Lowest): Built-in Defaults (in build.func)
```

---

## File Structure

### Minimal ct/AppName.sh Template

```
#!/usr/bin/env bash                          # [1] Shebang
                                             # [2] Copyright/License
source <(curl -s .../misc/build.func)        # [3] Import functions
                                             # [4] APP metadata
APP="AppName"                                # [5] Default values
var_tags="tag1;tag2"
var_cpu="2"
var_ram="2048"
...

header_info "$APP"                           # [6] Display header
variables                                    # [7] Process arguments
color                                        # [8] Setup colors
catch_errors                                 # [9] Setup error handling

function update_script() { ... }             # [10] Update function (optional)

start                                        # [11] Launch container creation
build_container
description
msg_ok "Completed Successfully!\n"
```

---

## Complete Script Template

### 1. File Header & Imports

```bash
#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
# Author: YourUsername
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/example/project

# Import main orchestrator
source <(curl -fsSL https://git.community-scripts.org/community-scripts/ProxmoxVE/raw/branch/main/misc/build.func)
```

> **⚠️ IMPORTANT**: Before opening a PR, change URL to `community-scripts` repo!

### 2. Application Metadata

```bash
# Application Configuration
APP="ApplicationName"
var_tags="tag1;tag2;tag3"      # Max 3-4 tags, no spaces, semicolon-separated

# Container Resources
var_cpu="2"                    # CPU cores
var_ram="2048"                 # RAM in MB
var_disk="10"                  # Disk in GB

# Container Type & OS
var_os="debian"                # Options: alpine, debian, ubuntu
var_version="12"               # Alpine: 3.20+, Debian: 11-13, Ubuntu: 20.04+
var_unprivileged="1"           # 1=unprivileged (secure), 0=privileged (rarely needed)
```

**Variable Naming Convention**:
- Variables exposed to user: `var_*` (e.g., `var_cpu`, `var_hostname`, `var_ssh`)
- Internal variables: lowercase (e.g., `container_id`, `app_version`)

### 3. Display & Initialization

```bash
# Display header ASCII art
header_info "$APP"

# Process command-line arguments and load configuration
variables

# Setup ANSI color codes and formatting
color

# Initialize error handling (trap ERR, EXIT, INT, TERM)
catch_errors
```

### 4. Update Function (Highly Recommended)

```bash
function update_script() {
  header_info

  # Always start with these checks
  check_container_storage
  check_container_resources

  # Verify app is installed
  if [[ ! -d /opt/appname ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Get latest version from GitHub
  RELEASE=$(curl -fsSL https://api.github.com/repos/user/repo/releases/latest | \
    grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')

  # Compare with saved version
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Updating ${APP} to v${RELEASE}"

    # Backup user data
    cp -r /opt/appname /opt/appname-backup

    # Perform update
    cd /opt
    wget -q "https://github.com/user/repo/releases/download/v${RELEASE}/app-${RELEASE}.tar.gz"
    tar -xzf app-${RELEASE}.tar.gz

    # Restore user data
    cp /opt/appname-backup/config/* /opt/appname/config/

    # Cleanup
    rm -rf app-${RELEASE}.tar.gz /opt/appname-backup

    # Save new version
    echo "${RELEASE}" > /opt/${APP}_version.txt

    msg_ok "Updated ${APP} to v${RELEASE}"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}."
  fi

  exit
}
```

### 5. Script Launch

```bash
# Start the container creation workflow
start

# Build the container with selected configuration
build_container

# Set container description/notes in Proxmox UI
description

# Display success message
msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
```

---

## Function Reference

### Core Functions (From build.func)

#### `variables()`

**Purpose**: Initialize container variables, load user arguments, setup orchestration

**Triggered by**: Called automatically at script start

**Behavior**:
1. Parse command-line arguments (if any)
2. Generate random UUID for session tracking
3. Load container storage from Proxmox
4. Initialize application-specific defaults
5. Setup SSH/environment configuration

#### `start()`

**Purpose**: Launch the container creation menu with 5 installation modes

**Menu Options**:
```
1. Default Installation (Quick setup, predefined settings)
2. Advanced Installation (19-step wizard with full control)
3. User Defaults (Load ~/.community-scripts/default.vars)
4. App Defaults (Load /defaults/AppName.vars)
5. Settings Menu (Interactive mode selection)
```

#### `build_container()`

**Purpose**: Main orchestrator for LXC container creation

**Operations**:
1. Validates all variables
2. Creates LXC container via `pct create`
3. Executes `install/AppName-install.sh` inside container
4. Monitors installation progress
5. Handles errors and rollback on failure

#### `description()`

**Purpose**: Set container description/notes visible in Proxmox UI

---

## Advanced Features

### 1. Custom Configuration Menus

If your app has additional setup beyond standard vars:

```bash
custom_app_settings() {
  CONFIGURE_DB=$(whiptail --title "Database Setup" \
    --yesno "Would you like to configure a custom database?" 8 60)

  if [[ $? -eq 0 ]]; then
    DB_HOST=$(whiptail --inputbox "Database Host:" 8 60 3>&1 1>&2 2>&3)
    DB_PORT=$(whiptail --inputbox "Database Port:" 8 60 "3306" 3>&1 1>&2 2>&3)
  fi
}

custom_app_settings
```

### 2. Update Function Patterns

Save installed version for update checks

### 3. Health Check Functions

Add custom validation:

```bash
function health_check() {
  header_info

  if [[ ! -d /opt/appname ]]; then
    msg_error "Application not found!"
    exit 1
  fi

  if ! systemctl is-active --quiet appname; then
    msg_error "Application service not running"
    exit 1
  fi

  msg_ok "Health check passed"
}
```

---

## Real Examples

### Example 1: Simple Web App (Debian-based)

```bash
#!/usr/bin/env bash
source <(curl -fsSL https://git.community-scripts.org/community-scripts/ProxmoxVE/raw/branch/main/misc/build.func)

APP="Homarr"
var_tags="dashboard;homepage"
var_cpu="2"
var_ram="1024"
var_disk="5"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  # Update logic here
}

start
build_container
description
msg_ok "Completed Successfully!\n"
```

---

## Troubleshooting

### Container Creation Fails

**Symptom**: `pct create` exits with error code 209

**Solution**:
```bash
# Check existing containers
pct list | grep CTID

# Remove conflicting container
pct destroy CTID

# Retry ct/AppName.sh
```

### Update Function Doesn't Detect New Version

**Debug**:
```bash
# Check version file
cat /opt/AppName_version.txt

# Test GitHub API
curl -fsSL https://api.github.com/repos/user/repo/releases/latest | grep tag_name
```

---

## Contribution Checklist

Before submitting a PR:

### Script Structure
- [ ] Shebang is `#!/usr/bin/env bash`
- [ ] Imports `build.func` from community-scripts repo
- [ ] Copyright header with author and source URL
- [ ] APP variable matches filename
- [ ] `var_tags` are semicolon-separated (no spaces)

### Default Values
- [ ] `var_cpu` set appropriately (2-4 for most apps)
- [ ] `var_ram` set appropriately (1024-4096 MB minimum)
- [ ] `var_disk` sufficient for app + data (5-20 GB)
- [ ] `var_os` is realistic

### Functions
- [ ] `update_script()` implemented
- [ ] Update function checks if app installed
- [ ] Proper error handling with `msg_error`

### Testing
- [ ] Script tested with default installation
- [ ] Script tested with advanced (19-step) installation
- [ ] Update function tested on existing installation

---

## Best Practices

### ✅ DO:

1. **Use meaningful defaults**
2. **Implement version tracking**
3. **Handle edge cases**
4. **Use proper messaging with msg_info/msg_ok/msg_error**

### ❌ DON'T:

1. **Hardcode versions**
2. **Use custom color codes** (use built-in variables)
3. **Forget error handling**
4. **Leave temporary files**

---

**Last Updated**: December 2025
**Compatibility**: ProxmoxVE with build.func v3+
