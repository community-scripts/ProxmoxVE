# install.func Integration Guide

How install.func integrates with the ProxmoxVE ecosystem and connects to other function libraries.

## Component Integration

### install.func in the Installation Pipeline

```
install/app-install.sh (container-side)
    │
    ├─ Sources: core.func (messaging)
    ├─ Sources: error_handler.func (error handling)
    │
    ├─ ★ Uses: install.func ★
    │  ├─ setting_up_container()
    │  ├─ network_check()
    │  ├─ update_os()
    │  └─ motd_ssh()
    │
    ├─ Uses: tools.func (package installation)
    │
    └─ Back to install.func:
       ├─ customize()
       └─ cleanup_lxc()
```

### Integration with tools.func

install.func and tools.func work together:

```
setting_up_container()          [install.func]
    │
update_os()                     [install.func]
    │
pkg_update()                    [tools.func]
setup_nodejs()                  [tools.func]
setup_mariadb()                 [tools.func]
    │
motd_ssh()                      [install.func]
customize()                     [install.func]
cleanup_lxc()                   [install.func]
```

---

## Dependencies

### External Dependencies

- `curl`, `wget` - For downloads
- `apt-get` or `apk` - Package management
- `ping` - Network verification
- `systemctl` or `rc-service` - Service management

### Internal Dependencies

```
install.func uses:
├─ core.func (for messaging and colors)
├─ error_handler.func (for error handling)
└─ tools.func (for package operations)
```

---

## Best Practices

### Always Follow This Pattern

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# 1. Setup error handling
catch_errors

# 2. Initialize container
setting_up_container

# 3. Verify network
network_check

# 4. Update OS
update_os

# 5. Installation (your code)
# ... install application ...

# 6. Configure access
motd_ssh

# 7. Customize
customize

# 8. Cleanup
cleanup_lxc
```

---

**Last Updated**: December 2025
**Maintainers**: community-scripts team
