# 🤖 AI Contribution Guidelines for ProxmoxVE

> **This documentation is intended for all AI assistants (GitHub Copilot, Claude, ChatGPT, etc.) contributing to this project.**

## 🎯 Core Principles

### 1. **Maximum Use of `tools.func` Functions**

We have an extensive library of helper functions. **NEVER** implement your own solutions when a function already exists!

### 2. **No Pointless Variables**

Only create variables when they:

- Are used multiple times
- Improve readability
- Are intended for configuration

### 3. **Consistent Script Structure**

All scripts follow an identical structure. Deviations are not acceptable.

### 4. **Bare-Metal Installation**

We do **NOT use Docker** for our installation scripts. All applications are installed directly on the system.

---

## 📁 Script Types and Their Structure

### CT Script (`ct/AppName.sh`)

```bash
#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: AuthorName (GitHubUsername)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://application-url.com

APP="AppName"
var_tags="${var_tags:-tag1;tag2;tag3}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/appname ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "appname" "YourUsername/YourRepo"; then
    msg_info "Stopping Service"
    systemctl stop appname
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/appname/data /opt/appname_data_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"

    # Build steps...

    msg_info "Restoring Data"
    cp -r /opt/appname_data_backup/. /opt/appname/data
    rm -rf /opt/appname_data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start appname
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:PORT${CL}"
```

### Install Script (`install/AppName-install.sh`)

```bash
#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: AuthorName (GitHubUsername)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://application-url.com

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  dependency1 \
  dependency2
msg_ok "Installed Dependencies"

# Runtime Setup (ALWAYS use our functions!)
NODE_VERSION="22" setup_nodejs
# or
PG_VERSION="16" setup_postgresql
# or
setup_uv
# etc.

fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"

msg_info "Setting up Application"
cd /opt/appname
# Build/Setup Schritte...
msg_ok "Set up Application"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/appname.service
[Unit]
Description=AppName Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/appname
ExecStart=/path/to/executable
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now appname
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
```

---

## 🔧 Available Helper Functions

### Release Management

| Function                      | Description                         | Example                                                       |
| ----------------------------- | ----------------------------------- | ------------------------------------------------------------- |
| `fetch_and_deploy_gh_release` | Fetches and installs GitHub Release | `fetch_and_deploy_gh_release "app" "owner/repo"`              |
| `check_for_gh_release`        | Checks for new version              | `if check_for_gh_release "app" "YourUsername/YourRepo"; then` |

**Modes for `fetch_and_deploy_gh_release`:**

```bash
# Tarball/Source (Standard)
fetch_and_deploy_gh_release "appname" "owner/repo"

# Binary (.deb)
fetch_and_deploy_gh_release "appname" "owner/repo" "binary"

# Prebuilt Archive
fetch_and_deploy_gh_release "appname" "owner/repo" "prebuild" "latest" "/opt/appname" "filename.tar.gz"

# Single Binary
fetch_and_deploy_gh_release "appname" "owner/repo" "singlefile" "latest" "/opt/appname" "binary-linux-amd64"
```

**Clean Install Flag:**

```bash
CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo"
```

### Runtime/Language Setup

| Function       | Variable(s)                   | Example                                              |
| -------------- | ----------------------------- | ---------------------------------------------------- |
| `setup_nodejs` | `NODE_VERSION`, `NODE_MODULE` | `NODE_VERSION="22" setup_nodejs`                     |
| `setup_uv`     | `PYTHON_VERSION`              | `PYTHON_VERSION="3.12" setup_uv`                     |
| `setup_go`     | `GO_VERSION`                  | `GO_VERSION="1.22" setup_go`                         |
| `setup_rust`   | `RUST_VERSION`, `RUST_CRATES` | `RUST_CRATES="monolith" setup_rust`                  |
| `setup_ruby`   | `RUBY_VERSION`                | `RUBY_VERSION="3.3" setup_ruby`                      |
| `setup_java`   | `JAVA_VERSION`                | `JAVA_VERSION="21" setup_java`                       |
| `setup_php`    | `PHP_VERSION`, `PHP_MODULES`  | `PHP_VERSION="8.3" PHP_MODULES="redis,gd" setup_php` |

### Database Setup

| Function              | Variable(s)                          | Example                                                     |
| --------------------- | ------------------------------------ | ----------------------------------------------------------- |
| `setup_postgresql`    | `PG_VERSION`, `PG_MODULES`           | `PG_VERSION="16" setup_postgresql`                          |
| `setup_postgresql_db` | `PG_DB_NAME`, `PG_DB_USER`           | `PG_DB_NAME="mydb" PG_DB_USER="myuser" setup_postgresql_db` |
| `setup_mariadb_db`    | `MARIADB_DB_NAME`, `MARIADB_DB_USER` | `MARIADB_DB_NAME="mydb" setup_mariadb_db`                   |
| `setup_mysql`         | `MYSQL_VERSION`                      | `setup_mysql`                                               |
| `setup_mongodb`       | `MONGO_VERSION`                      | `setup_mongodb`                                             |
| `setup_clickhouse`    | -                                    | `setup_clickhouse`                                          |

### Tools & Utilities

| Function            | Description                        |
| ------------------- | ---------------------------------- |
| `setup_adminer`     | Installs Adminer for DB management |
| `setup_composer`    | Install PHP Composer               |
| `setup_ffmpeg`      | Install FFmpeg                     |
| `setup_imagemagick` | Install ImageMagick                |
| `setup_gs`          | Install Ghostscript                |
| `setup_hwaccel`     | Configure hardware acceleration    |

### Helper Utilities

| Function                      | Description                  | Example                                   |
| ----------------------------- | ---------------------------- | ----------------------------------------- |
| `import_local_ip`             | Sets `$LOCAL_IP` variable    | `import_local_ip`                         |
| `ensure_dependencies`         | Checks/installs dependencies | `ensure_dependencies curl jq`             |
| `install_packages_with_retry` | APT install with retry       | `install_packages_with_retry nginx redis` |

---

## ❌ Anti-Patterns (NEVER use!)

### 1. Pointless Variables

```bash
# ❌ WRONG - unnecessary variables
APP_NAME="myapp"
APP_DIR="/opt/${APP_NAME}"
APP_USER="root"
APP_PORT="3000"
cd $APP_DIR

# ✅ CORRECT - use directly
cd /opt/myapp
```

### 2. Custom Download Logic

```bash
# ❌ WRONG - custom wget/curl logic
RELEASE=$(curl -s https://api.github.com/repos/YourUsername/YourRepo/releases/latest | jq -r '.tag_name')
wget https://github.com/YourUsername/YourRepo/archive/${RELEASE}.tar.gz
tar -xzf ${RELEASE}.tar.gz
mv repo-${RELEASE} /opt/myapp

# ✅ CORRECT - use our function
fetch_and_deploy_gh_release "myapp" "YourUsername/YourRepo" "tarball" "latest" "/opt/myapp"
```

### 3. Custom Version-Check Logic

```bash
# ❌ WRONG - custom version check
CURRENT=$(cat /opt/myapp/version.txt)
LATEST=$(curl -s https://api.github.com/repos/YourUsername/YourRepo/releases/latest | jq -r '.tag_name')
if [[ "$CURRENT" != "$LATEST" ]]; then
  # update...
fi

# ✅ CORRECT - use our function
if check_for_gh_release "myapp" "YourUsername/YourRepo"; then
  # update...
fi
```

### 4. Docker-based Installation

```bash
# ❌ WRONG - using Docker
docker pull myapp/myapp:latest
docker run -d --name myapp myapp/myapp:latest

# ✅ CORRECT - Bare-Metal Installation
fetch_and_deploy_gh_release "myapp" "YourUsername/YourRepo"
npm install && npm run build
```

### 5. Custom Runtime Installation

```bash
# ❌ WRONG - custom Node.js installation
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

# ✅ CORRECT - use our function
NODE_VERSION="22" setup_nodejs
```

### 6. Redundant echo Statements

```bash
# ❌ WRONG - custom logging messages
echo "Installing dependencies..."
apt install -y curl
echo "Done!"

# ✅ CORRECT - use msg_info/msg_ok
msg_info "Installing Dependencies"
$STD apt install -y curl
msg_ok "Installed Dependencies"
```

### 7. Missing $STD Usage

```bash
# ❌ WRONG - apt without $STD
apt install -y nginx

# ✅ CORRECT - with $STD for silent output
$STD apt install -y nginx
```

### 8. Wrapping `tools.func` Functions in msg Blocks

```bash
# ❌ WRONG - tools.func functions have their own msg_info/msg_ok!
msg_info "Installing Node.js"
NODE_VERSION="22" setup_nodejs
msg_ok "Installed Node.js"

msg_info "Updating Application"
CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"
msg_ok "Updated Application"

# ✅ CORRECT - call directly without msg wrapper
NODE_VERSION="22" setup_nodejs

CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"
```

**Functions with built-in messages (NEVER wrap in msg blocks):**

- `fetch_and_deploy_gh_release`
- `check_for_gh_release`
- `setup_nodejs`
- `setup_postgresql` / `setup_postgresql_db`
- `setup_mariadb` / `setup_mariadb_db`
- `setup_mongodb`
- `setup_mysql`
- `setup_ruby`
- `setup_go`
- `setup_java`
- `setup_php`
- `setup_uv`
- `setup_rust`
- `setup_composer`
- `setup_ffmpeg`
- `setup_imagemagick`
- `setup_gs`
- `setup_adminer`
- `setup_hwaccel`

### 9. Creating Unnecessary System Users

```bash
# ❌ WRONG - LXC containers run as root, no separate user needed
useradd -m -s /usr/bin/bash appuser
chown -R appuser:appuser /opt/appname
sudo -u appuser npm install

# ✅ CORRECT - run directly as root
cd /opt/appname
$STD npm install
```

### 10. Using `export` in .env Files

```bash
# ❌ WRONG - export is unnecessary in .env files
cat <<EOF >/opt/appname/.env
export DATABASE_URL=postgres://...
export SECRET_KEY=abc123
export NODE_ENV=production
EOF

# ✅ CORRECT - simple KEY=VALUE format (files are sourced with set -a)
cat <<EOF >/opt/appname/.env
DATABASE_URL=postgres://...
SECRET_KEY=abc123
NODE_ENV=production
EOF
```

### 11. Using External Shell Scripts

```bash
# ❌ WRONG - external script that gets executed
cat <<'EOF' >/opt/appname/install_script.sh
#!/bin/bash
cd /opt/appname
npm install
npm run build
EOF
chmod +x /opt/appname/install_script.sh
$STD bash /opt/appname/install_script.sh
rm -f /opt/appname/install_script.sh

# ✅ CORRECT - run commands directly
cd /opt/appname
$STD npm install
$STD npm run build
```

### 12. Using `sudo` in LXC Containers

```bash
# ❌ WRONG - sudo is unnecessary in LXC (already root)
sudo -u postgres psql -c "CREATE DATABASE mydb;"
sudo -u appuser npm install

# ✅ CORRECT - use functions or run directly as root
PG_DB_NAME="mydb" PG_DB_USER="myuser" setup_postgresql_db

cd /opt/appname
$STD npm install
```

### 13. Unnecessary `systemctl daemon-reload`

```bash
# ❌ WRONG - daemon-reload is only needed when MODIFYING existing services
cat <<EOF >/etc/systemd/system/appname.service
# ... service config ...
EOF
systemctl daemon-reload  # Unnecessary for new services!
systemctl enable -q --now appname

# ✅ CORRECT - new services don't need daemon-reload
cat <<EOF >/etc/systemd/system/appname.service
# ... service config ...
EOF
systemctl enable -q --now appname
```

### 14. Creating Custom Credentials Files

```bash
# ❌ WRONG - custom credentials file is not part of the standard template
msg_info "Saving Credentials"
cat <<EOF >~/appname.creds
Database User: ${DB_USER}
Database Pass: ${DB_PASS}
EOF
msg_ok "Saved Credentials"

# ✅ CORRECT - credentials are stored in .env or shown in final message only
# If you use setup_postgresql_db / setup_mariadb_db, a standard ~/[appname].creds is created automatically
```

### 15. Wrong Footer Pattern

```bash
# ❌ WRONG - old cleanup pattern with msg blocks
motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

# ✅ CORRECT - use cleanup_lxc function
motd_ssh
customize
cleanup_lxc
```

### 16. Manual Database Creation Instead of Functions

```bash
# ❌ WRONG - manual database creation
DB_USER="myuser"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE mydb WITH OWNER $DB_USER;"
$STD sudo -u postgres psql -d mydb -c "CREATE EXTENSION IF NOT EXISTS postgis;"

# ✅ CORRECT - use setup_postgresql_db function
# This sets PG_DB_USER, PG_DB_PASS, PG_DB_NAME automatically
PG_DB_NAME="mydb" PG_DB_USER="myuser" PG_DB_EXTENSIONS="postgis" setup_postgresql_db
```

### 17. Writing Files Without Heredocs

```bash
# ❌ WRONG - echo / printf / tee
echo "# Config" > /opt/app/config.yml
echo "port: 3000" >> /opt/app/config.yml

printf "# Config\nport: 3000\n" > /opt/app/config.yml
cat config.yml | tee /opt/app/config.yml
```

```bash
# ✅ CORRECT - always use a single heredoc
cat <<EOF >/opt/app/config.yml
# Config
port: 3000
EOF
```

---

## 📝 Important Rules

### Variable Declarations (CT Script)

```bash
# Standard declarations (ALWAYS present)
APP="AppName"
var_tags="${var_tags:-tag1;tag2}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
```

### Update-Script Pattern

```bash
function update_script() {
  header_info
  check_container_storage
  check_container_resources

  # 1. Check if installation exists
  if [[ ! -d /opt/appname ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # 2. Check for update
  if check_for_gh_release "appname" "YourUsername/YourRepo"; then
    # 3. Stop service
    msg_info "Stopping Service"
    systemctl stop appname
    msg_ok "Stopped Service"

    # 4. Backup data (if present)
    msg_info "Backing up Data"
    cp -r /opt/appname/data /opt/appname_data_backup
    msg_ok "Backed up Data"

    # 5. Perform clean install
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"

    # 6. Rebuild (if needed)
    cd /opt/appname
    $STD npm install
    $STD npm run build

    # 7. Restore data
    msg_info "Restoring Data"
    cp -r /opt/appname_data_backup/. /opt/appname/data
    rm -rf /opt/appname_data_backup
    msg_ok "Restored Data"

    # 8. Start service
    msg_info "Starting Service"
    systemctl start appname
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit  # IMPORTANT: Always end with exit!
}
```

### Systemd Service Pattern

```bash
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/appname.service
[Unit]
Description=AppName Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/appname
Environment=NODE_ENV=production
ExecStart=/usr/bin/node /opt/appname/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now appname
msg_ok "Created Service"
```

### Installation Script Footer

```bash
# ALWAYS at the end of the install script:
motd_ssh
customize
cleanup_lxc
```

---

## 📖 Reference: Good Example Scripts

Look at these recent well-implemented applications as reference:

### Container Scripts (Latest 10)

- [ct/thingsboard.sh](../ct/thingsboard.sh) - IoT platform with proper update_script
- [ct/unifi-os-server.sh](../ct/unifi-os-server.sh) - Complex setup with podman
- [ct/trip.sh](../ct/trip.sh) - Simple Ruby app
- [ct/fladder.sh](../ct/fladder.sh) - Media app with database
- [ct/qui.sh](../ct/qui.sh) - Lightweight utility
- [ct/kutt.sh](../ct/kutt.sh) - Node.js with PostgreSQL
- [ct/flatnotes.sh](../ct/flatnotes.sh) - Python notes app
- [ct/investbrain.sh](../ct/investbrain.sh) - Finance app
- [ct/gwn-manager.sh](../ct/gwn-manager.sh) - Network management
- [ct/sportarr.sh](../ct/sportarr.sh) - Specialized \*Arr variant

### Install Scripts (Latest)

- [install/unifi-os-server-install.sh](../install/unifi-os-server-install.sh) - Complex setup with API integration
- [install/trip-install.sh](../install/trip-install.sh) - Rails application setup
- [install/mail-archiver-install.sh](../install/mail-archiver-install.sh) - Email-related service

**Key things to notice:**

- Proper error handling with `catch_errors`
- Use of `check_for_gh_release` and `fetch_and_deploy_gh_release`
- Correct backup/restore patterns in `update_script`
- Footer always ends with `motd_ssh`, `customize`, `cleanup_lxc`
- JSON metadata files created for each app

---

## � JSON Metadata Files

Every application requires a JSON metadata file in `frontend/public/json/<appname>.json`.

### JSON Structure

```json
{
  "name": "AppName",
  "slug": "appname",
  "categories": [1],
  "date_created": "2026-01-16",
  "type": "ct",
  "updateable": true,
  "privileged": false,
  "interface_port": 3000,
  "documentation": "https://docs.appname.com/",
  "website": "https://appname.com/",
  "logo": "https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/appname.webp",
  "config_path": "/opt/appname/.env",
  "description": "Short description of the application and its purpose.",
  "install_methods": [
    {
      "type": "default",
      "script": "ct/appname.sh",
      "resources": {
        "cpu": 2,
        "ram": 2048,
        "hdd": 8,
        "os": "Debian",
        "version": "13"
      }
    }
  ],
  "default_credentials": {
    "username": null,
    "password": null
  },
  "notes": []
}
```

### Required Fields

| Field                 | Type    | Description                                        |
| --------------------- | ------- | -------------------------------------------------- |
| `name`                | string  | Display name of the application                    |
| `slug`                | string  | Lowercase, no spaces, used for filenames           |
| `categories`          | array   | Category ID(s) - see category list below           |
| `date_created`        | string  | Creation date (YYYY-MM-DD)                         |
| `type`                | string  | `ct` for container, `vm` for virtual machine       |
| `updateable`          | boolean | Whether update_script is implemented               |
| `privileged`          | boolean | Whether container needs privileged mode            |
| `interface_port`      | number  | Primary web interface port (or `null`)             |
| `documentation`       | string  | Link to official docs                              |
| `website`             | string  | Link to official website                           |
| `logo`                | string  | URL to application logo (preferably selfhst icons) |
| `config_path`         | string  | Path to main config file (or empty string)         |
| `description`         | string  | Brief description of the application               |
| `install_methods`     | array   | Installation configurations                        |
| `default_credentials` | object  | Default username/password (or null)                |
| `notes`               | array   | Additional notes/warnings                          |

### Categories

| ID  | Category                  |
| --- | ------------------------- |
| 0   | Miscellaneous             |
| 1   | Proxmox & Virtualization  |
| 2   | Operating Systems         |
| 3   | Containers & Docker       |
| 4   | Network & Firewall        |
| 5   | Adblock & DNS             |
| 6   | Authentication & Security |
| 7   | Backup & Recovery         |
| 8   | Databases                 |
| 9   | Monitoring & Analytics    |
| 10  | Dashboards & Frontends    |
| 11  | Files & Downloads         |
| 12  | Documents & Notes         |
| 13  | Media & Streaming         |
| 14  | \*Arr Suite               |
| 15  | NVR & Cameras             |
| 16  | IoT & Smart Home          |
| 17  | ZigBee, Z-Wave & Matter   |
| 18  | MQTT & Messaging          |
| 19  | Automation & Scheduling   |
| 20  | AI / Coding & Dev-Tools   |
| 21  | Webservers & Proxies      |
| 22  | Bots & ChatOps            |
| 23  | Finance & Budgeting       |
| 24  | Gaming & Leisure          |
| 25  | Business & ERP            |

### Notes Format

```json
"notes": [
    {
        "text": "Change the default password after first login!",
        "type": "warning"
    },
    {
        "text": "Requires at least 4GB RAM for optimal performance.",
        "type": "info"
    }
]
```

**Note types:** `info`, `warning`, `error`

### Examples with Credentials

```json
"default_credentials": {
    "username": "admin",
    "password": "admin"
}
```

Or no credentials:

```json
"default_credentials": {
    "username": null,
    "password": null
}
```

---

## 🔍 Checklist Before PR Creation

- [ ] No Docker installation used
- [ ] `fetch_and_deploy_gh_release` used for GitHub releases
- [ ] `check_for_gh_release` used for update checks
- [ ] `setup_*` functions used for runtimes (nodejs, postgresql, etc.)
- [ ] **`tools.func` functions NOT wrapped in msg_info/msg_ok blocks**
- [ ] No redundant variables (only when used multiple times)
- [ ] `$STD` before all apt/npm/build commands
- [ ] `msg_info`/`msg_ok`/`msg_error` for logging (only for custom code)
- [ ] Correct script structure followed (see templates)
- [ ] Update function present and functional (CT scripts)
- [ ] Data backup implemented in update function (if applicable)
- [ ] `motd_ssh`, `customize`, `cleanup_lxc` at the end of install scripts
- [ ] No custom download/version-check logic
- [ ] All links point to `community-scripts/ProxmoxVE` (not `ProxmoxVED`!)
- [ ] JSON metadata file created in `frontend/public/json/<appname>.json`
- [ ] Category IDs are valid (0-25)
- [ ] Default OS version is Debian 13 or newer (unless special requirement)
- [ ] Default resources are reasonable for the application

---

## 💡 Tips for AI Assistants

1. **ALWAYS search `tools.func` first** before implementing custom solutions
2. **Use recent scripts as reference** (Thingsboard, UniFi OS, Trip, Flatnotes, etc.)
3. **Ask when uncertain** instead of introducing wrong patterns
4. **Test via GitHub** - push to your fork and test with curl (not local bash)
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"
   # Wait 10-30 seconds after pushing - GitHub takes time to update files
   ```
5. **Consistency > Creativity** - follow established patterns strictly
6. **Check the templates** - they show the correct structure
7. **Don't wrap tools.func functions** - they handle their own msg_info/msg_ok output
8. **Minimal variables** - only create variables that are truly reused multiple times
9. **Always use $STD** - ensures silent/non-interactive execution
10. **Reference good examples** - look at recent additions in each category

---

## 🍒 Important: Cherry-Picking Your Files for PR Submission

⚠️ **CRITICAL**: When you submit your PR, you must use git cherry-pick to send ONLY your 3-4 files!

Why? Because `setup-fork.sh` modifies 600+ files to update links. If you commit all changes, your PR will be impossible to merge.

**See**: [README.md - Cherry-Pick Section](README.md#-cherry-pick-submitting-only-your-changes) for complete instructions on:

- Creating a clean submission branch
- Cherry-picking only your files (ct/myapp.sh, install/myapp-install.sh, frontend/public/json/myapp.json)
- Verifying your PR has only 3 file changes (not 600+)

**Quick reference**:

```bash
# Create clean branch from upstream
git fetch upstream
git checkout -b submit/myapp upstream/main

# Cherry-pick your commit(s) or manually add your 3-4 files
# Then push to your fork and create PR
```

---

## 📚 Further Documentation

- [CONTRIBUTING.md](CONTRIBUTING.md) - General contribution guidelines
- [GUIDE.md](GUIDE.md) - Detailed developer documentation
- [HELPER_FUNCTIONS.md](HELPER_FUNCTIONS.md) - Complete tools.func reference
- [README.md](README.md) - Cherry-pick guide and workflow instructions
- [../TECHNICAL_REFERENCE.md](../TECHNICAL_REFERENCE.md) - Technical deep dive
- [../EXIT_CODES.md](../EXIT_CODES.md) - Exit code reference
- [templates_ct/](templates_ct/) - CT script templates
- [templates_install/](templates_install/) - Install script templates
- [templates_json/](templates_json/) - JSON metadata templates
