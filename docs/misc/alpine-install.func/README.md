# alpine-install.func Documentation

## Overview

The `alpine-install.func` file provides Alpine Linux-specific installation and configuration functions for LXC containers. It complements the standard `install.func` with Alpine-specific operations using the apk package manager instead of apt.

## Purpose and Use Cases

- **Alpine Container Setup**: Initialize Alpine Linux containers with proper configuration
- **IPv6 Management**: Enable or disable IPv6 in Alpine with persistent configuration
- **Network Verification**: Verify connectivity in Alpine environments
- **SSH Configuration**: Setup SSH daemon on Alpine
- **Auto-Login Setup**: Configure passwordless root login for Alpine containers
- **Package Management**: Safe apk operations with error handling

## Quick Reference

### Key Function Groups
- **Initialization**: `setting_up_container()` - Alpine setup message
- **Network**: `verb_ip6()`, `network_check()` - IPv6 and connectivity
- **OS Configuration**: `update_os()` - Alpine package updates
- **SSH/MOTD**: `motd_ssh()` - SSH and login message setup
- **Container Customization**: `customize()`, `cleanup_lxc()` - Final setup

### Dependencies
- **External**: `apk`, `curl`, `wget`, `ping`
- **Internal**: Uses functions from `core.func`, `error_handler.func`

### Integration Points
- Used by: Alpine-based install scripts (alpine.sh, alpine-ntfy.sh, etc.)
- Uses: Environment variables from build.func
- Provides: Alpine-specific installation and management services

## Documentation Files

### 📊 [ALPINE_INSTALL_FUNC_FLOWCHART.md](./ALPINE_INSTALL_FUNC_FLOWCHART.md)
Visual execution flows showing Alpine container initialization and setup workflows.

### 📚 [ALPINE_INSTALL_FUNC_FUNCTIONS_REFERENCE.md](./ALPINE_INSTALL_FUNC_FUNCTIONS_REFERENCE.md)
Complete alphabetical reference of all functions with parameters and usage details.

### 💡 [ALPINE_INSTALL_FUNC_USAGE_EXAMPLES.md](./ALPINE_INSTALL_FUNC_USAGE_EXAMPLES.md)
Practical examples showing how to use Alpine installation functions.

### 🔗 [ALPINE_INSTALL_FUNC_INTEGRATION.md](./ALPINE_INSTALL_FUNC_INTEGRATION.md)
How alpine-install.func integrates with standard install workflows.

## Key Features

### Alpine-Specific Functions
- **apk Package Manager**: Alpine package operations (instead of apt-get)
- **OpenRC Support**: Alpine uses OpenRC init instead of systemd
- **Lightweight Setup**: Minimal dependencies appropriate for Alpine
- **IPv6 Configuration**: Persistent IPv6 settings via `/etc/network/interfaces`

### Network & Connectivity
- **IPv6 Toggle**: Enable/disable with persistent configuration
- **Connectivity Check**: Verify internet access in Alpine
- **DNS Verification**: Resolve domain names correctly
- **Retry Logic**: Automatic recovery from transient failures

### SSH & Auto-Login
- **SSH Daemon**: Setup and start sshd on Alpine
- **Root Keys**: Configure root SSH access
- **Auto-Login**: Optional automatic login without password
- **MOTD**: Custom login message on Alpine

## Function Categories

### 🔹 Core Functions
- `setting_up_container()` - Alpine container setup message
- `update_os()` - Update Alpine packages via apk
- `verb_ip6()` - Enable/disable IPv6 persistently
- `network_check()` - Verify network connectivity

### 🔹 SSH & Configuration Functions
- `motd_ssh()` - Configure SSH daemon on Alpine
- `customize()` - Apply Alpine-specific customizations
- `cleanup_lxc()` - Final cleanup

### 🔹 Service Management (OpenRC)
- `rc-update` - Enable/disable services for Alpine
- `rc-service` - Start/stop services on Alpine
- Service configuration files in `/etc/init.d/`

## Differences from Debian Install

| Feature | Debian (install.func) | Alpine (alpine-install.func) |
|---------|:---:|:---:|
| Package Manager | apt-get | apk |
| Init System | systemd | OpenRC |
| SSH Service | systemctl | rc-service |
| Config Files | /etc/systemd/ | /etc/init.d/ |
| Network Config | /etc/network/ or Netplan | /etc/network/interfaces |
| IPv6 Setup | netplan files | /etc/network/interfaces |
| Auto-Login | getty override | `/etc/inittab` or shell config |
| Size | ~200MB | ~100MB |

## Execution Flow for Alpine

```
Alpine Container Started
    ↓
source $FUNCTIONS_FILE_PATH
    ↓
setting_up_container()           ← Alpine setup message
    ↓
update_os()                      ← apk update
    ↓
verb_ip6()                       ← IPv6 configuration (optional)
    ↓
network_check()                  ← Verify connectivity
    ↓
[Application-Specific Installation]
    ↓
motd_ssh()                       ← Configure SSH/MOTD
customize()                      ← Apply customizations
    ↓
cleanup_lxc()                    ← Final cleanup
    ↓
Alpine Installation Complete
```

## Common Usage Patterns

### Basic Alpine Setup
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
setting_up_container
update_os

# Install Alpine-specific packages
apk add --no-cache curl wget git

# ... application installation ...

motd_ssh
customize
cleanup_lxc
```

### With IPv6 Enabled
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
setting_up_container
verb_ip6
update_os
network_check

# ... application installation ...

motd_ssh
customize
cleanup_lxc
```

### Installing Services
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
setting_up_container
update_os

# Install via apk
apk add --no-cache nginx

# Enable and start service on Alpine
rc-update add nginx
rc-service nginx start

motd_ssh
customize
cleanup_lxc
```

## Best Practices

### ✅ DO
- Use `apk add --no-cache` to reduce image size
- Enable IPv6 if application needs it (`verb_ip6`)
- Use `rc-service` for service management on Alpine
- Check `/etc/network/interfaces` for IPv6 persistence
- Test network connectivity before critical operations
- Use `$STD` for output suppression in production

### ❌ DON'T
- Use `apt-get` commands (Alpine doesn't have apt)
- Use `systemctl` (Alpine uses OpenRC, not systemd)
- Use `service` command (it may not exist on Alpine)
- Assume systemd exists on Alpine
- Forget to add `--no-cache` flag to `apk add`
- Hardcode paths from Debian (different on Alpine)

## Alpine-Specific Considerations

### Package Names
Some packages have different names on Alpine:
```bash
# Debian        → Alpine
# curl          → curl (same)
# wget          → wget (same)
# python3       → python3 (same)
# libpq5        → postgresql-client
# libmariadb3   → mariadb-client
```

### Service Management
```bash
# Debian (systemd)      → Alpine (OpenRC)
systemctl start nginx   → rc-service nginx start
systemctl enable nginx  → rc-update add nginx
systemctl status nginx  → rc-service nginx status
```

### Network Configuration
```bash
# Debian (Netplan)                → Alpine (/etc/network/interfaces)
/etc/netplan/01-*.yaml            → /etc/network/interfaces
netplan apply                      → Configure directly in interfaces

# Enable IPv6 persistently on Alpine:
# Add to /etc/network/interfaces:
# iface eth0 inet6 static
#     address <IPv6_ADDRESS>
```

## Troubleshooting

### "apk command not found"
- This is Alpine Linux, not Debian
- Install packages with `apk add` instead of `apt-get install`
- Example: `apk add --no-cache curl wget`

### "IPv6 not persisting after reboot"
- IPv6 must be configured in `/etc/network/interfaces`
- The `verb_ip6()` function handles this automatically
- Verify: `cat /etc/network/interfaces`

### "Service won't start on Alpine"
- Alpine uses OpenRC, not systemd
- Use `rc-service nginx start` instead of `systemctl start nginx`
- Enable service: `rc-update add nginx`
- Check logs: `/var/log/` or `rc-service nginx status`

### "Container too large"
- Alpine should be much smaller than Debian
- Verify using `apk add --no-cache` (removes package cache)
- Example: `apk add --no-cache nginx` (not `apk add nginx`)

## Related Documentation

- **[alpine-tools.func/](../alpine-tools.func/)** - Alpine tool installation
- **[install.func/](../install.func/)** - Standard installation functions
- **[core.func/](../core.func/)** - Utility functions
- **[error_handler.func/](../error_handler.func/)** - Error handling
- **[UPDATED_APP-install.md](../../UPDATED_APP-install.md)** - Application script guide

## Recent Updates

### Version 2.0 (Dec 2025)
- ✅ Enhanced IPv6 persistence configuration
- ✅ Improved OpenRC service management
- ✅ Better apk error handling
- ✅ Added Alpine-specific best practices documentation
- ✅ Streamlined SSH setup for Alpine

---

**Last Updated**: December 2025
**Maintainers**: community-scripts team
**License**: MIT
