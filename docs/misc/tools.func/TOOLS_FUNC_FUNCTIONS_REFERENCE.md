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
- `setup_mariadb()` - Install MariaDB server (distro packages by default)
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

### pkg_install()

Install one or more packages safely with automatic retry logic and error handling.

**Signature**:
```bash
pkg_install PACKAGE1 [PACKAGE2 ...]
```

**Parameters**:
- `PACKAGE1, PACKAGE2, ...` - Package names to install

**Returns**:
- `0` - All packages installed successfully
- `1` - Installation failed after retries

**Environment Variables**:
- `$STD` - Output suppression (`silent` or empty)

**Example**:
```bash
pkg_install curl wget git
```

---

### pkg_update()

Update package lists with automatic retry logic for network failures.

**Signature**:
```bash
pkg_update
```

**Parameters**: None

**Returns**:
- `0` - Package lists updated
- `1` - Failed after 3 retries

**Example**:
```bash
pkg_update
```

---

### pkg_remove()

Remove packages completely including dependencies.

**Signature**:
```bash
pkg_remove PACKAGE1 [PACKAGE2 ...]
```

**Parameters**:
- `PACKAGE1, PACKAGE2, ...` - Package names to remove

**Returns**:
- `0` - Packages removed
- `1` - Removal failed

**Example**:
```bash
pkg_remove old-package outdated-tool
```

---

### setup_deb822_repo()

Add repository in modern deb822 format (recommended over legacy format).

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
