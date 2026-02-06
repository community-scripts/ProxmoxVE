# 🛠️ Helper Functions Reference

**Quick reference for all helper functions available in `tools.func`**

> These functions are automatically available in install scripts via `$FUNCTIONS_FILE_PATH`

---

## 📋 Table of Contents

- [Scripts to Watch](#scripts-to-watch)
- [Runtime & Language Setup](#runtime--language-setup)
- [Database Setup](#database-setup)
- [GitHub Release Helpers](#github-release-helpers)
- [Tools & Utilities](#tools--utilities)
- [SSL/TLS](#ssltls)
- [Utility Functions](#utility-functions)
- [Package Management](#package-management)

---

## 📚 Scripts to Watch

**Learn from real, well-implemented scripts. Each app requires TWO files that work together:**

| File               | Location                     | Purpose                                                                  |
| ------------------ | ---------------------------- | ------------------------------------------------------------------------ |
| **CT Script**      | `ct/appname.sh`              | Runs on **Proxmox host** - creates container, contains `update_script()` |
| **Install Script** | `install/appname-install.sh` | Runs **inside container** - installs and configures the app              |

> ⚠️ **Both files are ALWAYS required!** The CT script calls the install script automatically during container creation.

Install scripts are **not** run directly by users; they are invoked by the CT script inside the container.

### Node.js + PostgreSQL

**Koel** - Music streaming with PHP + Node.js + PostgreSQL
| File | Link |
| ----------------- | -------------------------------------------------------- |
| CT (update logic) | [ct/koel.sh](../../ct/koel.sh) |
| Install | [install/koel-install.sh](../../install/koel-install.sh) |

**Actual Budget** - Finance app with npm global install
| File | Link |
| ----------------- | ------------------------------------------------------------------------ |
| CT (update logic) | [ct/actualbudget.sh](../../ct/actualbudget.sh) |
| Install | [install/actualbudget-install.sh](../../install/actualbudget-install.sh) |

### Python + uv

**MeTube** - YouTube downloader with Python uv + Node.js + Deno
| File | Link |
| ----------------- | ------------------------------------------------------------ |
| CT (update logic) | [ct/metube.sh](../../ct/metube.sh) |
| Install | [install/metube-install.sh](../../install/metube-install.sh) |

**Endurain** - Fitness tracker with Python uv + PostgreSQL/PostGIS
| File | Link |
| ----------------- | ---------------------------------------------------------------- |
| CT (update logic) | [ct/endurain.sh](../../ct/endurain.sh) |
| Install | [install/endurain-install.sh](../../install/endurain-install.sh) |

### Java + Gradle

**BookLore** - Book management with Java 21 + Gradle + MariaDB + Nginx
| File | Link |
| ----------------- | -------------------------------------------------------------- |
| CT (update logic) | [ct/booklore.sh](../../ct/booklore.sh) |
| Install | [install/booklore-install.sh](../../install/booklore-install.sh) |

### Pnpm + Meilisearch

**KaraKeep** - Bookmark manager with Pnpm + Meilisearch + Puppeteer
| File | Link |
| ----------------- | -------------------------------------------------------------- |
| CT (update logic) | [ct/karakeep.sh](../../ct/karakeep.sh) |
| Install | [install/karakeep-install.sh](../../install/karakeep-install.sh) |

### PHP + MariaDB/MySQL

**Wallabag** - Read-it-later with PHP + MariaDB + Redis + Nginx
| File | Link |
| ----------------- | ---------------------------------------------------------------- |
| CT (update logic) | [ct/wallabag.sh](../../ct/wallabag.sh) |
| Install | [install/wallabag-install.sh](../../install/wallabag-install.sh) |

**InvoiceNinja** - Invoicing with PHP + MariaDB + Supervisor
| File | Link |
| ----------------- | ------------------------------------------------------------------------ |
| CT (update logic) | [ct/invoiceninja.sh](../../ct/invoiceninja.sh) |
| Install | [install/invoiceninja-install.sh](../../install/invoiceninja-install.sh) |

**BookStack** - Wiki/Docs with PHP + MariaDB + Apache
| File | Link |
| ----------------- | ------------------------------------------------------------------ |
| CT (update logic) | [ct/bookstack.sh](../../ct/bookstack.sh) |
| Install | [install/bookstack-install.sh](../../install/bookstack-install.sh) |

### PHP + SQLite (Simple)

**Speedtest Tracker** - Speedtest with PHP + SQLite + Nginx
| File | Link |
| ----------------- | ---------------------------------------------------------------------------------- |
| CT (update logic) | [ct/speedtest-tracker.sh](../../ct/speedtest-tracker.sh) |
| Install | [install/speedtest-tracker-install.sh](../../install/speedtest-tracker-install.sh) |

---

## Runtime & Language Setup

### `setup_nodejs`

Install Node.js from NodeSource repository.

```bash
# Default (Node.js 24)
setup_nodejs

# Specific version
NODE_VERSION="20" setup_nodejs
NODE_VERSION="22" setup_nodejs
NODE_VERSION="24" setup_nodejs
```

### `setup_go`

Install Go programming language (latest stable).

```bash
setup_go

# Use in script
setup_go
cd /opt/myapp
$STD go build -o myapp .
```

### `setup_rust`

Install Rust via rustup.

```bash
setup_rust

# Use in script
setup_rust
source "$HOME/.cargo/env"
$STD cargo build --release
```

### `setup_uv`

Install Python uv package manager (fast pip/venv replacement).

```bash
# Default
setup_uv

# Install a specific Python version
PYTHON_VERSION="3.12" setup_uv

# Use in script
setup_uv
cd /opt/myapp
$STD uv sync --locked
```

### `setup_ruby`

Install Ruby from official repositories.

```bash
setup_ruby
```

### `setup_php`

Install PHP with configurable modules and FPM/Apache support.

```bash
# Basic PHP
setup_php

# Full configuration
PHP_VERSION="8.4" \
PHP_MODULE="mysqli,gd,curl,mbstring,xml,zip,ldap" \
PHP_FPM="YES" \
PHP_APACHE="YES" \
setup_php
```

**Environment Variables:**
| Variable | Default | Description |
| ------------- | ------- | ------------------------------- |
| `PHP_VERSION` | `8.4` | PHP version to install |
| `PHP_MODULE` | `""` | Comma-separated list of modules |
| `PHP_FPM` | `NO` | Install PHP-FPM |
| `PHP_APACHE` | `NO` | Install Apache module |

### `setup_composer`

Install PHP Composer package manager.

```bash
setup_php
setup_composer

# Use in script
$STD composer install --no-dev
```

### `setup_java`

Install Java (OpenJDK).

```bash
# Default (Java 21)
setup_java

# Specific version
JAVA_VERSION="17" setup_java
JAVA_VERSION="21" setup_java
```

---

## Database Setup

### `setup_mariadb`

Install MariaDB server.

```bash
setup_mariadb
```

### `setup_mariadb_db`

Create a MariaDB database and user. Sets `$MARIADB_DB_PASS` with the generated password.

```bash
setup_mariadb
MARIADB_DB_NAME="myapp_db" MARIADB_DB_USER="myapp_user" setup_mariadb_db

# After calling, these variables are available:
# $MARIADB_DB_NAME - Database name
# $MARIADB_DB_USER - Database user
# $MARIADB_DB_PASS - Generated password (saved to ~/[appname].creds)
```

### `setup_mysql`

Install MySQL server.

```bash
setup_mysql
```

### `setup_postgresql`

Install PostgreSQL server.

```bash
# Default (PostgreSQL 16)
setup_postgresql

# Specific version
PG_VERSION="16" setup_postgresql
PG_VERSION="16" setup_postgresql
```

### `setup_postgresql_db`

Create a PostgreSQL database and user. Sets `$PG_DB_PASS` with the generated password.

```bash
PG_VERSION="17" setup_postgresql
PG_DB_NAME="myapp_db" PG_DB_USER="myapp_user" setup_postgresql_db

# After calling, these variables are available:
# $PG_DB_NAME - Database name
# $PG_DB_USER - Database user
# $PG_DB_PASS - Generated password (saved to ~/[appname].creds)
```

### `setup_mongodb`

Install MongoDB server.

```bash
setup_mongodb
```

### `setup_clickhouse`

Install ClickHouse analytics database.

```bash
setup_clickhouse
```

---

## Advanced Repository Management

### `setup_deb822_repo`

The modern standard (Debian 12+) for adding external repositories. Automatically handles GPG keys and sources.

```bash
setup_deb822_repo \
  "nodejs" \
  "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" \
  "https://deb.nodesource.com/node_22.x" \
  "bookworm" \
  "main"
```

### `prepare_repository_setup`

A high-level helper that performs three critical tasks before adding a new repo:
1. Cleans up old repo files matching the names provided.
2. Removes old GPG keyrings from all standard locations.
3. Ensures APT is in a working state (fixes locks, runs update).

```bash
# Clean up old mysql/mariadb artifacts before setup
prepare_repository_setup "mariadb" "mysql"
```

### `cleanup_tool_keyrings`

Force-removes GPG keys for specific tools from `/usr/share/keyrings/`, `/etc/apt/keyrings/`, and `/etc/apt/trusted.gpg.d/`.

```bash
cleanup_tool_keyrings "docker" "kubernetes"
```

---

## GitHub Release Helpers

> **Note**: `fetch_and_deploy_gh_release` is the **preferred method** for downloading GitHub releases. It handles version tracking automatically. Only use `get_latest_github_release` if you need the version number separately.

### `fetch_and_deploy_gh_release`

**Primary method** for downloading and extracting GitHub releases. Handles version tracking automatically.

```bash
# Basic usage - downloads tarball to /opt/appname
fetch_and_deploy_gh_release "appname" "owner/repo"

# With explicit parameters
fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"

# Pre-built release with specific asset pattern
fetch_and_deploy_gh_release "koel" "koel/koel" "prebuild" "latest" "/opt/koel" "koel-*.tar.gz"

# Clean install (removes old directory first) - used in update_script
CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"
```

**Parameters:**
| Parameter | Default | Description |
| --------------- | ------------- | ----------------------------------------------------------------- |
| `name` | required | App name (for version tracking) |
| `repo` | required | GitHub repo (`owner/repo`) |
| `type` | `tarball` | Release type: `tarball`, `zipball`, `prebuild`, `binary` |
| `version` | `latest` | Version tag or `latest` |
| `dest` | `/opt/[name]` | Destination directory |
| `asset_pattern` | `""` | For `prebuild`: glob pattern to match asset (e.g. `app-*.tar.gz`) |

**Environment Variables:**
| Variable | Description |
| ----------------- | ------------------------------------------------------------ |
| `CLEAN_INSTALL=1` | Remove destination directory before extracting (for updates) |

### `check_for_gh_release`

Check if a newer version is available. Returns 0 if update needed, 1 if already at latest. **Use in `update_script()` function.**

```bash
# In update_script() function in ct/appname.sh
if check_for_gh_release "appname" "owner/repo"; then
  msg_info "Updating..."
  # Stop services, backup, update, restore, start
  CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo"
  msg_ok "Updated successfully!"
fi
```

### `get_latest_github_release`

Get the latest release version from a GitHub repository. **Only use if you need the version number separately** (e.g., for manual download or display).

```bash
RELEASE=$(get_latest_github_release "owner/repo")
echo "Latest version: $RELEASE"
```

---

## Tools & Utilities

### `setup_meilisearch`

Install Meilisearch, a lightning-fast search engine.

```bash
setup_meilisearch

# Use in script
$STD php artisan scout:sync-index-settings
```

### `setup_yq`

Install yq YAML processor.

```bash
setup_yq

# Use in script
yq '.server.port = 8080' -i config.yaml
````

### `setup_ffmpeg`

Install FFmpeg with common codecs.

```bash
setup_ffmpeg
```

### `setup_hwaccel`

Setup GPU hardware acceleration (Intel/AMD/NVIDIA).

```bash
# Only runs if GPU passthrough is detected (/dev/dri, /dev/nvidia0, /dev/kfd)
setup_hwaccel
```

### `setup_imagemagick`

Install ImageMagick 7 from source.

```bash
setup_imagemagick
```

### `setup_docker`

Install Docker Engine.

```bash
setup_docker
```

### `setup_adminer`

Install Adminer for database management.

```bash
setup_mariadb
setup_adminer

# Access at http://IP/adminer
```

---

## SSL/TLS

### `create_self_signed_cert`

Create a self-signed SSL certificate.

```bash
create_self_signed_cert

# Creates files at:
# /etc/ssl/[appname]/[appname].key
# /etc/ssl/[appname]/[appname].crt
```

---

## Utility Functions

### `verify_tool_version`

Validate that the installed major version matches the expected version. Useful during upgrades or troubleshooting.

```bash
# Verify Node.js is version 22
verify_tool_version "nodejs" "22" "$(node -v | grep -oP '^v\K[0-9]+')"
```

### `get_lxc_ip`

Set the `$LOCAL_IP` variable with the container's IP address.

```bash
get_lxc_ip
echo "Container IP: $LOCAL_IP"

# Use in config files
sed -i "s/localhost/$LOCAL_IP/g" /opt/myapp/config.yaml
```

### `ensure_dependencies`

Ensure packages are installed (installs if missing).

```bash
ensure_dependencies "jq" "unzip" "curl"
```

### `msg_info` / `msg_ok` / `msg_error` / `msg_warn`

Display formatted messages.

```bash
msg_info "Installing application..."
# ... do work ...
msg_ok "Installation complete"

msg_warn "Optional feature not available"
msg_error "Installation failed"
```

---

## Package Management

### `cleanup_lxc`

Final cleanup function - call at end of install script.

```bash
# At the end of your install script
motd_ssh
customize
cleanup_lxc  # Handles autoremove, autoclean, cache cleanup
```

### `install_packages_with_retry`

Install packages with automatic retry on failure.

```bash
install_packages_with_retry "package1" "package2" "package3"
```

### `prepare_repository_setup`

Prepare system for adding new repositories (cleanup old repos, keyrings).

```bash
prepare_repository_setup "mariadb" "mysql"
```

---

## Complete Examples

### Example 1: Node.js App with PostgreSQL (install script)

```bash
#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: YourUsername
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/example/myapp

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

# Setup runtimes and databases FIRST
NODE_VERSION="22" setup_nodejs
PG_VERSION="16" setup_postgresql
PG_DB_NAME="myapp" PG_DB_USER="myapp" setup_postgresql_db
get_lxc_ip

# Download app using fetch_and_deploy (handles version tracking)
fetch_and_deploy_gh_release "myapp" "example/myapp" "tarball" "latest" "/opt/myapp"

msg_info "Setting up MyApp"
cd /opt/myapp
$STD npm ci --production
msg_ok "Setup MyApp"

msg_info "Configuring MyApp"
cat <<EOF >/opt/myapp/.env
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost/${PG_DB_NAME}
HOST=${LOCAL_IP}
PORT=3000
EOF
msg_ok "Configured MyApp"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/myapp.service
[Unit]
Description=MyApp
After=network.target postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/node /opt/myapp/server.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now myapp
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
```

### Example 2: Matching Container Script (ct script)

```bash
#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: YourUsername
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/example/myapp

APP="MyApp"
var_tags="${var_tags:-webapp}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

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

  # check_for_gh_release returns true if update available
  if check_for_gh_release "myapp" "example/myapp"; then
    msg_info "Stopping Service"
    systemctl stop myapp
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    cp /opt/myapp/.env /tmp/myapp_env.bak
    msg_ok "Created Backup"

    # CLEAN_INSTALL=1 removes old dir before extracting
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "myapp" "example/myapp" "tarball" "latest" "/opt/myapp"

    msg_info "Restoring Config & Rebuilding"
    cp /tmp/myapp_env.bak /opt/myapp/.env
    rm /tmp/myapp_env.bak
    cd /opt/myapp
    $STD npm ci --production
    msg_ok "Restored Config & Rebuilt"

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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
```

### Example 3: PHP App with MariaDB (install script)

```bash
#!/usr/bin/env bash

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y nginx
msg_ok "Installed Dependencies"

# PHP with FPM and common modules
PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="bcmath,curl,gd,intl,mbstring,mysql,xml,zip" setup_php
setup_composer
setup_mariadb
MARIADB_DB_NAME="myapp" MARIADB_DB_USER="myapp" setup_mariadb_db
get_lxc_ip

# Download pre-built release (with asset pattern)
fetch_and_deploy_gh_release "myapp" "example/myapp" "prebuild" "latest" "/opt/myapp" "myapp-*.tar.gz"

msg_info "Configuring MyApp"
cd /opt/myapp
cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=http://${LOCAL_IP}|" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${MARIADB_DB_NAME}|" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${MARIADB_DB_USER}|" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${MARIADB_DB_PASS}|" .env
$STD composer install --no-dev --no-interaction
$STD php artisan key:generate --force
$STD php artisan migrate --force
chown -R www-data:www-data /opt/myapp
msg_ok "Configured MyApp"

# ... nginx config, service creation ...

motd_ssh
customize
cleanup_lxc
```
