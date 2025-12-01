# tools.func Integration Guide

How tools.func integrates with other components and provides package/tool services to the ProxmoxVE ecosystem.

## Component Relationships

### tools.func in the Installation Pipeline

```
ct/AppName.sh (host)
    │
    ├─ Calls build.func
    │
    └─ Creates Container
            │
            ▼
install/appname-install.sh (container)
            │
            ├─ Sources: core.func (colors, messaging)
            ├─ Sources: error_handler.func (error handling)
            ├─ Sources: install.func (container setup)
            │
            └─ ★ Sources: tools.func ★
                        │
                        ├─ pkg_update()
                        ├─ pkg_install()
                        ├─ setup_nodejs()
                        ├─ setup_php()
                        ├─ setup_mariadb()
                        └─ ... 30+ functions
```

### Integration with core.func

**tools.func uses core.func for**:
- `msg_info()` - Display progress messages
- `msg_ok()` - Display success messages
- `msg_error()` - Display error messages
- `msg_warn()` - Display warnings
- Color codes (GN, RD, YW, BL) for formatted output
- `$STD` variable - Output suppression control

**Example**:
```bash
# tools.func internally calls:
msg_info "Installing Node.js"      # Uses core.func
setup_nodejs "20"                  # Setup happens
msg_ok "Node.js installed"         # Uses core.func
```

### Integration with error_handler.func

**tools.func uses error_handler.func for**:
- Exit code mapping to error descriptions
- Automatic error trapping (catch_errors)
- Signal handlers (SIGINT, SIGTERM, EXIT)
- Structured error reporting

**Example**:
```bash
# If setup_nodejs fails, error_handler catches it:
catch_errors    # Calls from error_handler.func
setup_nodejs "20"  # If this exits non-zero
                   # error_handler logs and traps it
```

### Integration with install.func

**tools.func coordinates with install.func for**:
- Initial OS updates (install.func) → then tools (tools.func)
- Network verification before tool installation
- Package manager state validation
- Cleanup procedures after tool setup

**Sequence**:
```bash
setting_up_container()      # From install.func
network_check()             # From install.func
update_os()                 # From install.func

pkg_update                  # From tools.func
setup_nodejs()              # From tools.func

motd_ssh()                  # From install.func
customize()                 # From install.func
cleanup_lxc()               # From install.func
```

---

## Integration with alpine-tools.func (Alpine Containers)

### When to Use tools.func vs alpine-tools.func

| Feature | tools.func (Debian) | alpine-tools.func (Alpine) |
|---------|:---:|:---:|
| Package Manager | apt-get | apk |
| Installation Scripts | install/*.sh | install/*-alpine.sh |
| Tool Setup | `setup_nodejs()` (apt) | `setup_nodejs()` (apk) |
| Repository | `setup_deb822_repo()` | `add_community_repo()` |
| Services | systemctl | rc-service |

### Automatic Selection

Installation scripts detect OS and source appropriate functions:

```bash
# install/myapp-install.sh
if grep -qi 'alpine' /etc/os-release; then
  # Alpine detected - uses alpine-tools.func
  apk_update
  apk_add package
else
  # Debian detected - uses tools.func
  pkg_update
  pkg_install package
fi
```

---

## Dependencies Management

### External Dependencies

```
tools.func requires:
├─ curl          (for HTTP requests, GPG keys)
├─ wget          (for downloads)
├─ apt-get       (package manager)
├─ gpg           (GPG key management)
├─ openssl       (for encryption)
└─ systemctl     (service management on Debian)
```

### Internal Function Dependencies

```
setup_nodejs()
    ├─ Calls: setup_deb822_repo()
    ├─ Calls: pkg_update()
    ├─ Calls: pkg_install()
    └─ Uses: msg_info(), msg_ok() [from core.func]

setup_mariadb()
    ├─ Calls: setup_deb822_repo()
    ├─ Calls: pkg_update()
    ├─ Calls: pkg_install()
    └─ Uses: msg_info(), msg_ok()

setup_docker()
    ├─ Calls: cleanup_repo_metadata()
    ├─ Calls: setup_deb822_repo()
    ├─ Calls: pkg_update()
    └─ Uses: msg_info(), msg_ok()
```

---

## Function Call Graph

### Complete Installation Dependency Tree

```
install/app-install.sh
    │
    ├─ setting_up_container()         [install.func]
    │
    ├─ network_check()                [install.func]
    │
    ├─ update_os()                    [install.func]
    │
    ├─ pkg_update()                   [tools.func]
    │   └─ Calls: apt-get update (with retry)
    │
    ├─ setup_nodejs("20")             [tools.func]
    │   ├─ setup_deb822_repo()        [tools.func]
    │   │   └─ Calls: apt-get update
    │   ├─ pkg_update()               [tools.func]
    │   └─ pkg_install()              [tools.func]
    │
    ├─ setup_php("8.3")               [tools.func]
    │   └─ Similar to setup_nodejs
    │
    ├─ setup_mariadb("11")            [tools.func]
    │   └─ Similar to setup_nodejs
    │
    ├─ motd_ssh()                     [install.func]
    │
    ├─ customize()                    [install.func]
    │
    └─ cleanup_lxc()                  [install.func]
```

---

## Configuration Management

### Environment Variables Used by tools.func

```bash
# Output control
STD="silent"              # Suppress apt/apk output
VERBOSE="yes"             # Show all output

# Package management
DEBIAN_FRONTEND="noninteractive"

# Tool versions (optional)
NODEJS_VERSION="20"
PHP_VERSION="8.3"
POSTGRES_VERSION="16"
```

### Tools Configuration Files Created

```
/opt/
├─ nodejs_version.txt       # Node.js version
├─ php_version.txt          # PHP version
├─ mariadb_version.txt      # MariaDB version
├─ postgresql_version.txt   # PostgreSQL version
├─ docker_version.txt       # Docker version
└─ [TOOL]_version.txt       # For all installed tools

/etc/apt/sources.list.d/
├─ nodejs.sources           # Node.js repo (deb822)
├─ docker.sources           # Docker repo (deb822)
└─ [name].sources           # Other repos (deb822)
```

---

## Error Handling Integration

### Exit Codes from tools.func

| Code | Meaning | Handled By |
|------|:---:|:---:|
| 0 | Success | Normal flow |
| 1 | Package installation failed | error_handler.func |
| 100-101 | APT error | error_handler.func |
| 127 | Command not found | error_handler.func |

### Automatic Cleanup on Failure

```bash
# If any step fails in install script:
catch_errors
pkg_update        # Fail here?
setup_nodejs      # Doesn't get here

# error_handler automatically:
├─ Logs error
├─ Captures exit code
├─ Calls cleanup_lxc()
└─ Exits with proper code
```

---

## Integration with build.func

### Variable Flow

```
ct/app.sh
    │
    ├─ var_cpu="2"
    ├─ var_ram="2048"
    ├─ var_disk="10"
    │
    └─ Calls: build_container()     [build.func]
              │
              └─ Creates container
                 │
                 └─ Calls: install/app-install.sh
                    │
                    └─ Uses: tools.func for installation
```

### Resource Considerations

tools.func respects container resource limits:
- Large package installations respect allocated RAM
- Database setups use allocated disk space
- Build tools (gcc, make) stay within CPU allocation

---

## Version Management

### How tools.func Tracks Versions

Each tool installation creates a version file:

```bash
# setup_nodejs() creates:
echo "20.10.5" > /opt/nodejs_version.txt

# Used by update scripts:
CURRENT=$(cat /opt/nodejs_version.txt)
LATEST=$(curl ... # fetch latest)
if [[ "$LATEST" != "$CURRENT" ]]; then
  # Update needed
fi
```

### Integration with Update Functions

```bash
# In ct/app.sh:
function update_script() {
  # Check Node version
  RELEASE=$(curl ... | jq '.version')
  CURRENT=$(cat /opt/nodejs_version.txt)

  if [[ "$RELEASE" != "$CURRENT" ]]; then
    # Use tools.func to upgrade
    setup_nodejs "$RELEASE"
  fi
}
```

---

## Best Practices for Integration

### ✅ DO

1. **Call functions in proper order**
   ```bash
   pkg_update
   setup_tool "version"
   ```

2. **Use $STD for production**
   ```bash
   export STD="silent"
   pkg_install curl wget
   ```

3. **Check for existing installations**
   ```bash
   command -v nodejs >/dev/null || setup_nodejs "20"
   ```

4. **Coordinate with install.func**
   ```bash
   setting_up_container
   update_os                    # From install.func
   setup_nodejs                 # From tools.func
   motd_ssh                     # Back to install.func
   ```

### ❌ DON'T

1. **Don't skip pkg_update**
   ```bash
   # Bad - may fail due to stale cache
   pkg_install curl
   ```

2. **Don't hardcode versions**
   ```bash
   # Bad
   apt-get install nodejs=20.x

   # Good
   setup_nodejs "20"
   ```

3. **Don't mix package managers**
   ```bash
   # Bad
   apt-get install curl
   apk add wget
   ```

4. **Don't ignore errors**
   ```bash
   # Bad
   setup_docker || true

   # Good
   if ! setup_docker; then
     msg_error "Docker failed"
     exit 1
   fi
   ```

---

## Troubleshooting Integration Issues

### "Package installation fails"
- Check: `pkg_update` was called first
- Check: Package name is correct for OS
- Solution: Manually verify in container

### "Tool not accessible after installation"
- Check: Tool added to PATH
- Check: Version file created
- Solution: `which toolname` to verify

### "Repository conflicts"
- Check: No duplicate repositories
- Solution: `cleanup_repo_metadata()` before adding

### "Alpine-specific errors when using Debian tools"
- Problem: Using tools.func functions on Alpine
- Solution: Use alpine-tools.func instead

---

**Last Updated**: December 2025
**Maintainers**: community-scripts team
**Integration Status**: All components fully integrated
