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
- `setup_ruby(VERSION)` - Install Ruby with gem
- `setup_golang(VERSION)` - Install Go programming language

**Databases**:
- `setup_mariadb(VERSION)` - Install MariaDB server
- `setup_postgresql(VERSION)` - Install PostgreSQL
- `setup_mongodb(VERSION)` - Install MongoDB
- `setup_redis(VERSION)` - Install Redis cache

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

**Parameters**:
- `APPREPO`: GitHub repository (e.g., `owner/repo`)
- `TYPE`: Asset type (`binary`, `tarball`, `prebuild`, `singlefile`, `binary_tarball`)
- `VERSION`: Specific tag or `latest` (Default: `latest`)
- `DEST`: Target directory (Default: `/opt/$APP`)
- `ASSET_PATTERN`: Regex or string pattern to match the release asset

**Environment Variables**:
- `CLEAN_INSTALL=1`: Removes the destination directory before extracting.

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

## Tool Installation Functions

### setup_nodejs(VERSION)

Install Node.js and npm from official repositories.

**Signature**:
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

### setup_mariadb(VERSION)

Install MariaDB server and client utilities.

**Signature**:
```bash
setup_mariadb VERSION
```

**Parameters**:
- `VERSION` - MariaDB version (e.g., "10.6", "11.0")

**Returns**:
- `0` - Installation successful
- `1` - Installation failed

**Creates**:
- `/opt/mariadb_version.txt` - Version file

**Example**:
```bash
setup_mariadb "11.0"
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
setup_mariadb "11"            # Install MariaDB

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
setup_mariadb "11"
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
