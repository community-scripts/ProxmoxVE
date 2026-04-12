# tools.func Functions Reference

Complete alphabetical reference of all functions in tools.func with parameters, usage, and examples.

## Function Index

### Package Management
- `pkg_install()` - Install packages safely with retry
- `pkg_update()` - Update package lists with retry
- `pkg_remove()` - Remove packages cleanly

### Repository Management
- `setup_deb822_repo()` - Add repository in modern deb822 format
- `cleanup_repo_metadata()` - Clean GPG keys and old repositories
- `check_repository()` - Verify repository accessibility

### Tool Installation Functions (30+)

**Programming Languages**:
- `setup_nodejs(VERSION)` - Install Node.js and npm
- `setup_php(VERSION)` - Install PHP-FPM and CLI
- `setup_python(VERSION)` - Install Python 3 with pip
- `setup_uv()` - Install Python uv (modern & fast)
- `setup_ruby(VERSION)` - Install Ruby with gem
- `setup_golang(VERSION)` - Install Go programming language
- `setup_java(VERSION)` - Install OpenJDK (Adoptium)

**Databases**:
- `setup_mariadb()` - Install MariaDB server
- `setup_mariadb_db()` - Create user/db in MariaDB
- `setup_postgresql(VERSION)` - Install PostgreSQL
- `setup_postgresql_db()` - Create user/db in PostgreSQL
- `setup_mongodb(VERSION)` - Install MongoDB
- `setup_redis(VERSION)` - Install Redis cache
- `setup_meilisearch()` - Install Meilisearch engine

**Web Servers**:
- `setup_nginx()` - Install Nginx
- `setup_apache()` - Install Apache HTTP Server
- `setup_caddy()` - Install Caddy
- `setup_traefik()` - Install Traefik proxy

**Containers**:
- `setup_docker()` - Install Docker
- `setup_podman()` - Install Podman

**Development**:
- `setup_git()` - Install Git
- `setup_docker_compose()` - Install Docker Compose
- `setup_composer()` - Install PHP Composer
- `setup_build_tools()` - Install build-essential
- `setup_yq()` - Install mikefarah/yq processor

**Monitoring**:
- `setup_grafana()` - Install Grafana
- `setup_prometheus()` - Install Prometheus
- `setup_telegraf()` - Install Telegraf

**System**:
- `setup_wireguard()` - Install WireGuard VPN
- `setup_netdata()` - Install Netdata monitoring
- `setup_tailscale()` - Install Tailscale
- (+ more...)

---

## Core Functions

### install_packages_with_retry()

Install one or more packages safely with automatic retry logic (3 attempts), APT refresh, and lock handling.

**Signature**:
```bash
install_packages_with_retry PACKAGE1 [PACKAGE2 ...]
```

**Parameters**:
- `PACKAGE1, PACKAGE2, ...` - Package names to install

**Returns**:
- `0` - All packages installed successfully
- `1` - Installation failed after all retries

**Features**:
- Automatically sets `DEBIAN_FRONTEND=noninteractive`
- Handles DPKG lock errors with `dpkg --configure -a`
- Retries on transient network or APT failures

**Example**:
```bash
install_packages_with_retry curl wget git
```

---

### upgrade_packages_with_retry()

Upgrades installed packages with the same robust retry logic as the installation helper.

**Signature**:
```bash
upgrade_packages_with_retry
```

**Returns**:
- `0` - Upgrade successful
- `1` - Upgrade failed

---

### fetch_and_deploy_gh_release()

The primary tool for downloading and installing software from GitHub Releases. Supports binaries, tarballs, and Debian packages.

**Signature**:
```bash
fetch_and_deploy_gh_release APPREPO TYPE [VERSION] [DEST] [ASSET_PATTERN]
```

**Environment Variables**:
- `APPREPO`: GitHub repository (e.g., `owner/repo`)
- `TYPE`: Asset type (`binary`, `tarball`, `prebuild`, `singlefile`)
- `VERSION`: Specific tag or `latest` (Default: `latest`)
- `DEST`: Target directory (Default: `/opt/$APP`)
- `ASSET_PATTERN`: Regex or string pattern to match the release asset (Required for `prebuild` and `singlefile`)

**Supported Operation Modes**:
- `tarball`: Downloads and extracts the source tarball.
- `binary`: Detects host architecture and installs a `.deb` package using `apt` or `dpkg`.
- `prebuild`: Downloads and extracts a pre-built binary archive (supports `.tar.gz`, `.zip`, `.tgz`, `.txz`).
- `singlefile`: Downloads a single binary file to the destination.

**Environment Variables**:
- `CLEAN_INSTALL=1`: Removes all contents of the destination directory before extraction.
- `DPKG_FORCE_CONFOLD=1`: Forces `dpkg` to keep old config files during package updates.
- `SYSTEMD_OFFLINE=1`: Used automatically for `.deb` installs to prevent systemd-tmpfiles failures in unprivileged containers.

**Example**:
```bash
fetch_and_deploy_gh_release "muesli/duf" "binary" "latest" "/opt/duf" "duf_.*_linux_amd64.tar.gz"
```

---

### check_for_gh_release()

Checks if a newer version is available on GitHub compared to the installed version.

**Signature**:
```bash
check_for_gh_release APP REPO
```

**Example**:
```bash
if check_for_gh_release "nodejs" "nodesource/distributions"; then
  # update logic
fi
```

---

### prepare_repository_setup()

Performs safe repository preparation by cleaning up old files, keyrings, and ensuring the APT system is in a working state.

**Signature**:
```bash
prepare_repository_setup REPO_NAME [REPO_NAME2 ...]
```

**Example**:
```bash
prepare_repository_setup "mariadb" "mysql"
```

---

### verify_tool_version()

Validates if the installed major version matches the expected version.

**Signature**:
```bash
verify_tool_version NAME EXPECTED INSTALLED
```

**Example**:
```bash
verify_tool_version "nodejs" "22" "$(node -v | grep -oP '^v\K[0-9]+')"
```

---

### setup_deb822_repo()

Add repository in modern deb822 format.

**Signature**:
```bash
setup_deb822_repo NAME GPG_URL REPO_URL SUITE COMPONENT [ARCHITECTURES] [ENABLED]
```

**Parameters**:
- `NAME` - Repository name (e.g., "nodejs")
- `GPG_URL` - URL to GPG key (e.g., https://example.com/key.gpg)
- `REPO_URL` - Main repository URL (e.g., https://example.com/repo)
- `SUITE` - Repository suite (e.g., "jammy", "bookworm")
- `COMPONENT` - Repository component (e.g., "main", "testing")
- `ARCHITECTURES` - Optional Comma-separated list of architectures (e.g., "amd64,arm64")
- `ENABLED` - Optional "true" or "false" (default: "true")

**Returns**:
- `0` - Repository added successfully
- `1` - Repository setup failed

**Example**:
```bash
setup_deb822_repo \
  "nodejs" \
  "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" \
  "https://deb.nodesource.com/node_20.x" \  
  "jammy" \
  "main"
```

---

### cleanup_repo_metadata()

Clean up GPG keys and old repository configurations.

**Signature**:
```bash
cleanup_repo_metadata
```

**Parameters**: None

**Returns**:
- `0` - Cleanup complete

**Example**:
```bash
cleanup_repo_metadata
```

---

## Tool Installation Functions

### setup_nodejs()

Install Node.js and npm from official repositories. Handles legacy version cleanup (nvm) automatically.

**Signature**:
```bash
setup_nodejs
```

**Environment Variables**:
- `NODE_VERSION`: Major version to install (e.g. "20", "22", "24"). Default: "24".
- `NODE_MODULE`: Optional npm package to install globally during setup (e.g. "pnpm", "yarn").

**Example**:
```bash
NODE_VERSION="22" NODE_MODULE="pnpm" setup_nodejs
```

---

### setup_php()

Install PHP with configurable extensions and FPM/Apache integration.

**Signature**:
```bash
setup_php
```

**Environment Variables**:
- `PHP_VERSION`: Version to install (e.g. "8.3", "8.4"). Default: "8.4".
- `PHP_MODULE`: Comma-separated list of additional extensions.
- `PHP_FPM`: Set to "YES" to install php-fpm.
- `PHP_APACHE`: Set to "YES" to install libapache2-mod-php.

**Example**:
```bash
PHP_VERSION="8.3" PHP_FPM="YES" PHP_MODULE="mysql,xml,zip" setup_php
```

---

### setup_mariadb_db()

Creates a new MariaDB database and a dedicated user with all privileges. Automatically generates a password if not provided and saves it to a credentials file.

**Environment Variables**:
- `MARIADB_DB_NAME`: Name of the database (required)
- `MARIADB_DB_USER`: Name of the database user (required)
- `MARIADB_DB_PASS`: User password (optional, auto-generated if omitted)

**Example**:
```bash
MARIADB_DB_NAME="myapp" MARIADB_DB_USER="myapp_user" setup_mariadb_db
```

---

### setup_postgresql_db()

Creates a new PostgreSQL database and a dedicated user/role with all privileges. Automatically generates a password if not provided and saves it to a credentials file.

**Environment Variables**:
- `PG_DB_NAME`: Name of the database (required)
- `PG_DB_USER`: Name of the database user (required)
- `PG_DB_PASS`: User password (optional, auto-generated if omitted)

---

### setup_java()

Installs Temurin JDK.

**Signature**:
```bash
JAVA_VERSION="21" setup_java
```

**Parameters**:
- `JAVA_VERSION` - JDK version (e.g., "17", "21") (default: "21")

**Example**:
```bash
JAVA_VERSION="17" setup_java
```

---

### setup_uv()

Installs `uv` (modern Python package manager).

**Signature**:
```bash
PYTHON_VERSION="3.13" setup_uv
```

**Parameters**:
- `PYTHON_VERSION` - Optional Python version to pre-install via uv (e.g., "3.12", "3.13")

**Example**:
```bash
PYTHON_VERSION="3.13" setup_uv
```

---

### setup_go()

Installs Go programming language.

**Signature**:
```bash
GO_VERSION="1.23" setup_go
```

**Parameters**:
- `GO_VERSION` - Go version to install (default: "1.23")

**Example**:
```bash
GO_VERSION="1.24" setup_go
```

---

### setup_yq()

Installs `yq` (YAML processor).

**Signature**:
```bash
setup_yq
```

**Example**:
```bash
setup_yq
```

---

### setup_composer()

Installs PHP Composer.

**Signature**:
```bash
setup_composer
```

**Example**:
```bash
setup_composer
```

---

### setup_meilisearch()

Install and configure Meilisearch search engine.

**Environment Variables**:
- `MEILISEARCH_BIND`: Address and port to bind to (Default: "127.0.0.1:7700")
- `MEILISEARCH_ENV`: Environment mode (Default: "production")

---

### setup_yq()

Install the `mikefarah/yq` YAML processor. Removes existing non-compliant versions.

**Example**:
```bash
setup_yq
yq eval '.app.version = "1.0.0"' -i config.yaml
```

---

### setup_composer()

Install or update the PHP Composer package manager. Handles `COMPOSER_ALLOW_SUPERUSER` automatically and performs self-updates if already installed.

**Example**:
```bash
setup_php
setup_composer
$STD composer install --no-dev
```

---

### setup_build_tools()

Install the `build-essential` package suite for compiling software.

---

### setup_uv()

Install the modern Python package manager `uv`. Extremely fast replacement for pip/venv.

**Environment Variables**:
- `PYTHON_VERSION`: Major.Minor version to ensure is installed.

**Example**:
```bash
PYTHON_VERSION="3.12" setup_uv
uv sync --locked
```

---

### setup_java()

Install OpenJDK via the Adoptium repository.

**Environment Variables**:
- `JAVA_VERSION`: Major version to install (e.g. "17", "21"). Default: "21".

**Example**:
```bash
JAVA_VERSION="21" setup_java
```

---
```bash
setup_nodejs VERSION
```

**Parameters**:
- `VERSION` - Node.js version (e.g., "20", "22", "lts")

**Returns**:
- `0` - Installation successful
- `1` - Installation failed

**Creates**:
- `/opt/nodejs_version.txt` - Version file

**Example**:
```bash
setup_nodejs "20"
```

---

### setup_php(VERSION)

Install PHP-FPM, CLI, and common extensions.

**Signature**:
```bash
setup_php VERSION
```

**Parameters**:
- `VERSION` - PHP version (e.g., "8.2", "8.3")

**Returns**:
- `0` - Installation successful
- `1` - Installation failed

**Creates**:
- `/opt/php_version.txt` - Version file

**Example**:
```bash
setup_php "8.3"
```

---

### setup_mariadb()

Install MariaDB server and client utilities.

**Signature**:
```bash
setup_mariadb                         # Uses distribution packages (recommended)
MARIADB_VERSION="11.4" setup_mariadb  # Uses official MariaDB repository
```

**Variables**:
- `MARIADB_VERSION` - (optional) Specific MariaDB version
  - Not set or `"latest"`: Uses distribution packages (most reliable, avoids mirror issues)
  - Specific version (e.g., `"11.4"`, `"12.2"`): Uses official MariaDB repository

**Returns**:
- `0` - Installation successful
- `1` - Installation failed

**Creates**:
- `/opt/mariadb_version.txt` - Version file

**Example**:
```bash
# Recommended: Use distribution packages (stable, no mirror issues)
setup_mariadb

# Specific version from official repository
MARIADB_VERSION="11.4" setup_mariadb
```

---

### setup_postgresql(VERSION)

Install PostgreSQL server and client utilities.

**Signature**:
```bash
setup_postgresql VERSION
```

**Parameters**:
- `VERSION` - PostgreSQL version (e.g., "14", "15", "16")

**Returns**:
- `0` - Installation successful
- `1` - Installation failed

**Creates**:
- `/opt/postgresql_version.txt` - Version file

**Example**:
```bash
setup_postgresql "16"
```

---

### setup_docker()

Install Docker and Docker CLI.

**Signature**:
```bash
setup_docker
```

**Parameters**: None

**Returns**:
- `0` - Installation successful
- `1` - Installation failed

**Creates**:
- `/opt/docker_version.txt` - Version file

**Example**:
```bash
setup_docker
```

---

### setup_composer()

Install PHP Composer (dependency manager).

**Signature**:
```bash
setup_composer
```

**Parameters**: None

**Returns**:
- `0` - Installation successful
- `1` - Installation failed

**Creates**:
- `/usr/local/bin/composer` - Composer executable

**Example**:
```bash
setup_composer
```

---

### setup_build_tools()

Install build-essential and development tools (gcc, make, etc.).

**Signature**:
```bash
setup_build_tools
```

**Parameters**: None

**Returns**:
- `0` - Installation successful
- `1` - Installation failed

**Example**:
```bash
setup_build_tools
```

---

## System Configuration

### setting_up_container()

Display setup message and initialize container environment.

**Signature**:
```bash
setting_up_container
```

**Example**:
```bash
setting_up_container
# Output: ⏳ Setting up container...
```

---

### motd_ssh()

Configure SSH daemon and MOTD for container.

**Signature**:
```bash
motd_ssh
```

**Example**:
```bash
motd_ssh
# Configures SSH and creates MOTD
```

---

### customize()

Apply container customizations and final setup.

**Signature**:
```bash
customize
```

**Example**:
```bash
customize
```

---

### cleanup_lxc()

Final cleanup of temporary files and logs.

**Signature**:
```bash
cleanup_lxc
```

**Example**:
```bash
cleanup_lxc
# Removes temp files, finalizes installation
```

---

## Usage Patterns

### Basic Installation Sequence

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

pkg_update                    # Update package lists
setup_nodejs "20"             # Install Node.js
setup_mariadb                 # Install MariaDB (distribution packages)

# ... application installation ...

motd_ssh                      # Setup SSH/MOTD
customize                     # Apply customizations
cleanup_lxc                   # Final cleanup
```

### Tool Chain Installation

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# Install full web stack
pkg_update
setup_nginx
setup_php "8.3"
setup_mariadb  # Uses distribution packages
setup_composer
```

### With Repository Setup

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

pkg_update

# Add Node.js repository
setup_deb822_repo \
  "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" \
  "nodejs" \
  "jammy" \
  "https://deb.nodesource.com/node_20.x" \
  "main"

pkg_update
setup_nodejs "20"
```

---

**Last Updated**: December 2025
**Total Functions**: 30+
**Maintained by**: community-scripts team
