# alpine-tools.func Documentation

## Overview

The `alpine-tools.func` file provides Alpine Linux-specific tool installation functions for package and service management within Alpine LXC containers. It complements `tools.func` with Alpine-specific implementations using the apk package manager.

## Purpose and Use Cases

- **Alpine Tool Installation**: Install services and tools using apk on Alpine
- **Package Management**: Safe apk operations with error handling
- **Service Setup**: Install and configure common services on Alpine
- **Dependency Management**: Handle Alpine-specific package dependencies
- **Repository Management**: Setup and manage Alpine package repositories

## Quick Reference

### Key Function Groups
- **Package Operations**: Alpine-specific apk commands with error handling
- **Service Installation**: Install databases, web servers, tools on Alpine
- **Repository Setup**: Configure Alpine community and testing repositories
- **Tool Setup**: Install development tools and utilities

### Dependencies
- **External**: `apk`, `curl`, `wget`
- **Internal**: Uses functions from `core.func`, `error_handler.func`

### Integration Points
- Used by: Alpine-based application install scripts
- Uses: Environment variables from build.func
- Provides: Alpine package and tool installation services

## Documentation Files

### 📊 [ALPINE_TOOLS_FUNC_FLOWCHART.md](./ALPINE_TOOLS_FUNC_FLOWCHART.md)
Visual execution flows for package operations and tool installation on Alpine.

### 📚 [ALPINE_TOOLS_FUNC_FUNCTIONS_REFERENCE.md](./ALPINE_TOOLS_FUNC_FUNCTIONS_REFERENCE.md)
Complete alphabetical reference of all Alpine tool functions.

### 💡 [ALPINE_TOOLS_FUNC_USAGE_EXAMPLES.md](./ALPINE_TOOLS_FUNC_USAGE_EXAMPLES.md)
Practical examples for common Alpine installation patterns.

### 🔗 [ALPINE_TOOLS_FUNC_INTEGRATION.md](./ALPINE_TOOLS_FUNC_INTEGRATION.md)
How alpine-tools.func integrates with Alpine installation workflows.

## Key Features

### Alpine Package Management
- **apk Add**: Safe package installation with error handling
- **apk Update**: Update package lists with retry logic
- **apk Del**: Remove packages and dependencies
- **Repository Configuration**: Add community and testing repos

### Alpine Tool Coverage
- **Web Servers**: nginx, lighttpd
- **Databases**: mariadb, postgresql, sqlite
- **Development**: gcc, make, git, node.js (via apk)
- **Services**: sshd, docker, podman
- **Utilities**: curl, wget, htop, vim

### Error Handling
- **Retry Logic**: Automatic recovery from transient failures
- **Dependency Resolution**: Handle missing dependencies
- **Lock Management**: Wait for apk locks to release
- **Error Reporting**: Clear error messages

## Function Categories

### 🔹 Package Management
- `apk_update()` - Update Alpine packages with retry
- `apk_add()` - Install packages safely
- `apk_del()` - Remove packages completely

### 🔹 Repository Functions
- `add_community_repo()` - Enable community repositories
- `add_testing_repo()` - Enable testing repositories
- `setup_apk_repo()` - Configure custom apk repositories

### 🔹 Service Installation Functions
- `setup_nginx()` - Install and configure nginx
- `setup_mariadb()` - Install MariaDB on Alpine
- `setup_postgresql()` - Install PostgreSQL
- `setup_docker()` - Install Docker on Alpine
- `setup_nodejs()` - Install Node.js from Alpine repos

### 🔹 Development Tools
- `setup_build_tools()` - Install gcc, make, build-essential
- `setup_git()` - Install git version control
- `setup_python()` - Install Python 3 and pip

## Alpine vs Debian Package Differences

| Package | Debian | Alpine |
|---------|:---:|:---:|
| nginx | `apt-get install nginx` | `apk add nginx` |
| mariadb | `apt-get install mariadb-server` | `apk add mariadb` |
| PostgreSQL | `apt-get install postgresql` | `apk add postgresql` |
| Node.js | `apt-get install nodejs npm` | `apk add nodejs npm` |
| Docker | Special setup | `apk add docker` |
| Python | `apt-get install python3 python3-pip` | `apk add python3 py3-pip` |

## Common Usage Patterns

### Basic Alpine Tool Installation
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# Update package lists
apk_update

# Install nginx
apk_add nginx

# Start service
rc-service nginx start
rc-update add nginx
```

### With Community Repository
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# Enable community repo for more packages
add_community_repo

# Update and install
apk_update
apk_add postgresql postgresql-client

# Start service
rc-service postgresql start
```

### Development Environment
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# Install build tools
setup_build_tools
setup_git
setup_nodejs "20"

# Install application
git clone https://example.com/app
cd app
npm install
```

## Best Practices

### ✅ DO
- Always use `apk add --no-cache` to keep images small
- Call `apk_update()` before installing packages
- Use community repository for more packages (`add_community_repo`)
- Handle apk locks gracefully with retry logic
- Use `$STD` variable for output control
- Check if tool already installed before reinstalling

### ❌ DON'T
- Use `apt-get` commands (Alpine doesn't have apt)
- Install packages without `--no-cache` flag
- Hardcode Alpine-specific paths
- Mix Alpine and Debian commands
- Forget to enable services with `rc-update`
- Use `systemctl` (Alpine has OpenRC, not systemd)

## Alpine Repository Configuration

### Default Repositories
Alpine comes with main repository enabled by default. Additional repos:

```bash
# Community repository (apk add php, go, rust, etc.)
add_community_repo

# Testing repository (bleeding edge packages)
add_testing_repo
```

### Repository Locations
```bash
/etc/apk/repositories      # Main repo list
/etc/apk/keys/             # GPG keys for repos
/var/cache/apk/            # Package cache
```

## Package Size Optimization

Alpine is designed for small container images:

```bash
# DON'T: Leaves package cache (increases image size)
apk add nginx

# DO: Remove cache to reduce size
apk add --no-cache nginx

# Expected sizes:
# Alpine base: ~5MB
# Alpine + nginx: ~10-15MB
# Debian base: ~75MB
# Debian + nginx: ~90-95MB
```

## Service Management on Alpine

### Using OpenRC
```bash
# Start service immediately
rc-service nginx start

# Stop service
rc-service nginx stop

# Restart service
rc-service nginx restart

# Enable at boot
rc-update add nginx

# Disable at boot
rc-update del nginx

# List enabled services
rc-update show
```

## Troubleshooting

### "apk: lock is held by PID"
```bash
# Alpine apk database is locked (another process using apk)
# Wait a moment
sleep 5
apk_update

# Or manually:
rm /var/lib/apk/lock 2>/dev/null || true
apk update
```

### "Package not found"
```bash
# May be in community or testing repository
add_community_repo
apk_update
apk_add package-name
```

### "Repository not responding"
```bash
# Alpine repo may be slow or unreachable
# Try updating again with retry logic
apk_update  # Built-in retry logic

# Or manually retry
sleep 10
apk update
```

### "Service fails to start"
```bash
# Check service status on Alpine
rc-service nginx status

# View logs
tail /var/log/nginx/error.log

# Verify configuration
nginx -t
```

## Related Documentation

- **[alpine-install.func/](../alpine-install.func/)** - Alpine installation functions
- **[tools.func/](../tools.func/)** - Debian/standard tool installation
- **[core.func/](../core.func/)** - Utility functions
- **[error_handler.func/](../error_handler.func/)** - Error handling
- **[UPDATED_APP-install.md](../../UPDATED_APP-install.md)** - Application script guide

## Recent Updates

### Version 2.0 (Dec 2025)
- ✅ Enhanced apk error handling and retry logic
- ✅ Improved repository management
- ✅ Better service management with OpenRC
- ✅ Added Alpine-specific optimization guidance
- ✅ Enhanced package cache management

---

**Last Updated**: December 2025
**Maintainers**: community-scripts team
**License**: MIT
