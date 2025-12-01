# 🛠️ **Application Installation Scripts (install/AppName-install.sh)**

**Modern Guide to Writing In-Container Installation Scripts**

> **Updated**: December 2025
> **Context**: Integrated with tools.func, error_handler.func, and install.func
> **Examples Used**: `/install/pihole-install.sh`, `/install/mealie-install.sh`

---

## 📋 Table of Contents

- [Overview](#overview)
- [Execution Context](#execution-context)
- [File Structure](#file-structure)
- [Complete Script Template](#complete-script-template)
- [Installation Phases](#installation-phases)
- [Function Reference](#function-reference)
- [Best Practices](#best-practices)
- [Real Examples](#real-examples)
- [Troubleshooting](#troubleshooting)
- [Contribution Checklist](#contribution-checklist)

---

## Overview

### Purpose

Installation scripts (`install/AppName-install.sh`) **run inside the LXC container** and are responsible for:

1. Setting up the container OS (updates, packages)
2. Installing application dependencies
3. Downloading and configuring the application
4. Setting up services and systemd units
5. Creating version tracking files for updates
6. Generating credentials/configurations
7. Final cleanup and validation

### Execution Flow

```
ct/AppName.sh (Proxmox Host)
       ↓
build_container()
       ↓
pct exec CTID bash -c "$(cat install/AppName-install.sh)"
       ↓
install/AppName-install.sh (Inside Container)
       ↓
Container Ready with App Installed
```

---

## Execution Context

### Environment Variables Available

```bash
# From Proxmox/Container
CTID                    # Container ID (100, 101, etc.)
PCT_OSTYPE             # OS type (alpine, debian, ubuntu)
HOSTNAME               # Container hostname

# From build.func
FUNCTIONS_FILE_PATH    # Bash functions library (core.func + tools.func)
VERBOSE                # Verbose mode (yes/no)
STD                    # Standard redirection variable (silent/empty)

# From install.func
APP                    # Application name
NSAPP                  # Normalized app name (lowercase, no spaces)
METHOD                 # Installation method (ct/install)
RANDOM_UUID            # Session UUID for telemetry
```

---

## File Structure

### Minimal install/AppName-install.sh Template

```bash
#!/usr/bin/env bash                          # [1] Shebang

# [2] Copyright/Metadata
# Copyright (c) 2021-2025 community-scripts ORG
# Author: YourUsername
# License: MIT
# Source: https://example.com

# [3] Load functions
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# [4] Installation steps
msg_info "Installing Dependencies"
$STD apt-get install -y package1 package2
msg_ok "Installed Dependencies"

# [5] Final setup
motd_ssh
customize
cleanup_lxc
```

---

## Complete Script Template

### Phase 1: Header & Initialization

```bash
#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
# Author: YourUsername
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/application/repo

# Load all available functions (from core.func + tools.func)
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# Initialize environment
color                   # Setup ANSI colors and icons
verb_ip6                # Configure IPv6 (if needed)
catch_errors           # Setup error traps
setting_up_container   # Verify OS is ready
network_check          # Verify internet connectivity
update_os              # Update packages (apk/apt)
```

### Phase 2: Dependency Installation

```bash
msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  wget \
  git \
  nano \
  build-essential \
  libssl-dev \
  python3-dev
msg_ok "Installed Dependencies"
```

### Phase 3: Tool Setup (Using tools.func)

```bash
# Setup specific tool versions
NODE_VERSION="22" setup_nodejs
PHP_VERSION="8.4" setup_php
PYTHON_VERSION="3.12" setup_uv
```

### Phase 4: Application Download & Setup

```bash
# Download from GitHub
RELEASE=$(curl -fsSL https://api.github.com/repos/user/repo/releases/latest | \
  grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')

wget -q "https://github.com/user/repo/releases/download/v${RELEASE}/app-${RELEASE}.tar.gz"
cd /opt
tar -xzf app-${RELEASE}.tar.gz
rm -f app-${RELEASE}.tar.gz
```

### Phase 5: Configuration Files

```bash
# Using cat << EOF (multiline)
cat <<'EOF' >/etc/nginx/sites-available/appname
server {
    listen 80;
    server_name _;
    root /opt/appname/public;
    index index.php index.html;
}
EOF

# Using sed for replacements
sed -i -e "s|^DB_HOST=.*|DB_HOST=localhost|" \
       -e "s|^DB_USER=.*|DB_USER=appuser|" \
       /opt/appname/.env
```

### Phase 6: Database Setup (If Needed)

```bash
msg_info "Setting up Database"

DB_NAME="appname_db"
DB_USER="appuser"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)

# For MySQL/MariaDB
mysql -u root <<EOF
CREATE DATABASE ${DB_NAME};
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

msg_ok "Database setup complete"
```

### Phase 7: Permission & Ownership

```bash
msg_info "Setting permissions"

# Web applications typically run as www-data
chown -R www-data:www-data /opt/appname
chmod -R 755 /opt/appname
chmod -R 644 /opt/appname/*
chmod 755 /opt/appname/*/.*

msg_ok "Permissions set"
```

### Phase 8: Service Configuration

```bash
# Enable systemd service
systemctl enable -q --now appname

# Or for OpenRC (Alpine)
rc-service appname start
rc-update add appname default

# Verify service is running
if systemctl is-active --quiet appname; then
  msg_ok "Service running successfully"
else
  msg_error "Service failed to start"
  journalctl -u appname -n 20
  exit 1
fi
```

### Phase 9: Version Tracking

```bash
# Essential for update detection
echo "${RELEASE}" > /opt/${APP}_version.txt

# Or with additional metadata
cat > /opt/${APP}_version.txt <<EOF
Version: ${RELEASE}
InstallDate: $(date)
InstallMethod: ${METHOD}
EOF
```

### Phase 10: Final Setup & Cleanup

```bash
# Display MOTD and enable autologin
motd_ssh

# Final customization
customize

# Clean up package manager cache
msg_info "Cleaning up"
apt-get -y autoremove
apt-get -y autoclean
msg_ok "Cleaned"

# Or for Alpine
apk cache clean
rm -rf /var/cache/apk/*

# System cleanup
cleanup_lxc
```

---

## Installation Phases

### Phase 1: Container OS Setup
- Network interface brought up and configured
- Internet connectivity verified
- Package lists updated
- All OS packages upgraded to latest versions

### Phase 2: Base Dependencies
```bash
msg_info "Installing Base Dependencies"
$STD apt-get install -y \
  curl wget git nano build-essential
msg_ok "Installed Base Dependencies"
```

### Phase 3: Tool Installation
```bash
NODE_VERSION="22" setup_nodejs
PHP_VERSION="8.4" setup_php
```

### Phase 4: Application Setup
```bash
RELEASE=$(curl -fsSL https://api.github.com/repos/user/repo/releases/latest | \
  grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
wget -q "https://github.com/user/repo/releases/download/v${RELEASE}/app.tar.gz"
```

### Phase 5: Configuration
Application-specific configuration files and environment setup

### Phase 6: Service Registration
Enable and verify systemd services are running

---

## Function Reference

### Core Messaging Functions

#### `msg_info(message)`

Displays an info message with spinner animation

```bash
msg_info "Installing application"
# Output: ⏳ Installing application (with spinning animation)
```

#### `msg_ok(message)`

Displays success message with checkmark

```bash
msg_ok "Installation completed"
# Output: ✔️ Installation completed
```

#### `msg_error(message)`

Displays error message and exits

```bash
msg_error "Installation failed"
# Output: ✖️ Installation failed
```

### Package Management

#### `$STD` Variable

Controls output verbosity

```bash
# Silent mode (respects VERBOSE setting)
$STD apt-get install -y nginx
```

#### `update_os()`

Updates OS packages

```bash
update_os
# Runs: apt update && apt upgrade
```

### Tool Installation Functions

#### `setup_nodejs()`

Installs Node.js with optional global modules

```bash
NODE_VERSION="22" setup_nodejs
NODE_VERSION="22" NODE_MODULE="yarn,@vue/cli" setup_nodejs
```

#### `setup_php()`

Installs PHP with optional extensions

```bash
PHP_VERSION="8.4" PHP_MODULE="bcmath,curl,gd,intl,redis" setup_php
```

#### Other Tools

```bash
setup_mariadb     # MariaDB database
setup_mysql       # MySQL database
setup_postgresql  # PostgreSQL
setup_docker      # Docker Engine
setup_composer    # PHP Composer
setup_python      # Python 3
setup_ruby        # Ruby
setup_rust        # Rust
```

### Cleanup Functions

#### `cleanup_lxc()`

Comprehensive container cleanup

- Removes package manager caches
- Cleans temporary files
- Clears language package caches
- Removes systemd journal logs

```bash
cleanup_lxc
# Output: ⏳ Cleaning up
#         ✔️ Cleaned
```

---

## Best Practices

### ✅ DO:

1. **Always Use $STD for Commands**
```bash
# ✅ Good: Respects VERBOSE setting
$STD apt-get install -y nginx
```

2. **Generate Random Passwords Safely**
```bash
# ✅ Good: Alphanumeric only
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
```

3. **Check Command Success**
```bash
# ✅ Good: Verify success
if ! wget -q "https://example.com/file.tar.gz"; then
  msg_error "Download failed"
  exit 1
fi
```

4. **Set Proper Permissions**
```bash
# ✅ Good: Explicit permissions
chown -R www-data:www-data /opt/appname
chmod -R 755 /opt/appname
```

5. **Save Version for Update Checks**
```bash
# ✅ Good: Version tracked
echo "${RELEASE}" > /opt/${APP}_version.txt
```

6. **Handle Alpine vs Debian Differences**
```bash
# ✅ Good: Detect OS
if grep -qi 'alpine' /etc/os-release; then
  apk add package
else
  apt-get install -y package
fi
```

### ❌ DON'T:

1. **Hardcode Versions**
```bash
# ❌ Bad: Won't auto-update
wget https://example.com/app-1.2.3.tar.gz
```

2. **Use Root Without Password**
```bash
# ❌ Bad: Security risk
mysql -u root
```

3. **Forget Error Handling**
```bash
# ❌ Bad: Silent failures
wget https://example.com/file
tar -xzf file
```

4. **Leave Temporary Files**
```bash
# ✅ Always cleanup
rm -rf /opt/app-${RELEASE}.tar.gz
```

---

## Real Examples

### Example 1: Node.js Application

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

color
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Node.js"
NODE_VERSION="22" setup_nodejs
msg_ok "Node.js installed"

msg_info "Installing Application"
cd /opt
RELEASE=$(curl -fsSL https://api.github.com/repos/user/repo/releases/latest | \
  grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
wget -q "https://github.com/user/repo/releases/download/v${RELEASE}/app.tar.gz"
tar -xzf app.tar.gz
echo "${RELEASE}" > /opt/app_version.txt
msg_ok "Application installed"

systemctl enable --now app
cleanup_lxc
```

### Example 2: PHP Application with Database

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

color
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.4" PHP_MODULE="bcmath,curl,pdo_mysql" setup_php
MARIADB_VERSION="11.4" setup_mariadb

# Database setup
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
mysql -u root <<EOF
CREATE DATABASE appdb;
CREATE USER 'appuser'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL ON appdb.* TO 'appuser'@'localhost';
FLUSH PRIVILEGES;
EOF

# App installation
cd /opt
wget -q https://github.com/user/repo/releases/latest/download/app.tar.gz
tar -xzf app.tar.gz

# Configuration
cat > /opt/app/.env <<EOF
DB_HOST=localhost
DB_NAME=appdb
DB_USER=appuser
DB_PASS=${DB_PASS}
EOF

chown -R www-data:www-data /opt/app
systemctl enable --now php-fpm
cleanup_lxc
```

---

## Troubleshooting

### Installation Hangs

**Check internet connectivity**:
```bash
ping -c 1 8.8.8.8
```

**Enable verbose mode**:
```bash
# In ct/AppName.sh, before running
VERBOSE="yes" bash install/AppName-install.sh
```

### Package Not Found

**Update package lists**:
```bash
apt update
apt-cache search package_name
```

### Service Won't Start

**Check logs**:
```bash
journalctl -u appname -n 50
systemctl status appname
```

---

## Contribution Checklist

Before submitting a PR:

### Structure
- [ ] Shebang is `#!/usr/bin/env bash`
- [ ] Loads functions from `$FUNCTIONS_FILE_PATH`
- [ ] Copyright header with author
- [ ] Clear phase comments

### Installation
- [ ] `setting_up_container` called early
- [ ] `network_check` before downloads
- [ ] `update_os` before package installation
- [ ] All errors checked properly

### Functions
- [ ] Uses `msg_info/msg_ok/msg_error` for status
- [ ] Uses `$STD` for command output silencing
- [ ] Version saved to `/opt/${APP}_version.txt`
- [ ] Proper permissions set

### Cleanup
- [ ] `motd_ssh` called for final setup
- [ ] `customize` called for options
- [ ] `cleanup_lxc` called at end

### Testing
- [ ] Tested with default settings
- [ ] Tested with advanced (19-step) mode
- [ ] Service starts and runs correctly

---

**Last Updated**: December 2025
**Compatibility**: ProxmoxVE with install.func v3+
