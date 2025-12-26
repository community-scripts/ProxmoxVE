# install.func Documentation

## Overview

The `install.func` file provides container installation workflow orchestration and fundamental operations for applications deployed inside LXC containers. It handles network setup, OS configuration, connectivity verification, and installation mechanics.

## Purpose and Use Cases

- **Container Setup**: Initialize new container with proper configuration
- **Network Verification**: Verify IPv4 and IPv6 connectivity
- **OS Configuration**: Update OS, apply system settings
- **Installation Workflow**: Orchestrate application installation steps
- **Error Handling**: Comprehensive signal trapping and error recovery

## Quick Reference

### Key Function Groups
- **Initialization**: `setting_up_container()` - Setup message and environment
- **Network**: `network_check()`, `verb_ip6()` - Connectivity verification
- **OS Configuration**: `update_os()` - OS updates and package management
- **Installation**: `motd_ssh()`, `customize()` - Container customization
- **Cleanup**: `cleanup_lxc()` - Final container cleanup

### Dependencies
- **External**: `curl`, `apt-get`, `ping`, `dns` utilities
- **Internal**: Uses functions from `core.func`, `error_handler.func`, `tools.func`

### Integration Points
- Used by: All install/*.sh scripts at startup
- Uses: Environment variables from build.func and core.func
- Provides: Container initialization and management services

## Documentation Files

### 📊 [INSTALL_FUNC_FLOWCHART.md](./INSTALL_FUNC_FLOWCHART.md)
Visual execution flows showing initialization, network checks, and installation workflows.

### 📚 [INSTALL_FUNC_FUNCTIONS_REFERENCE.md](./INSTALL_FUNC_FUNCTIONS_REFERENCE.md)
Complete alphabetical reference of all functions with parameters, dependencies, and usage details.

### 💡 [INSTALL_FUNC_USAGE_EXAMPLES.md](./INSTALL_FUNC_USAGE_EXAMPLES.md)
Practical examples showing how to use installation functions and common patterns.

### 🔗 [INSTALL_FUNC_INTEGRATION.md](./INSTALL_FUNC_INTEGRATION.md)
How install.func integrates with other components and provides installation services.

## Key Features

### Container Initialization
- **Environment Setup**: Prepare container variables and functions
- **Message System**: Display installation progress with colored output
- **Error Handlers**: Setup signal trapping for proper cleanup

### Network & Connectivity
- **IPv4 Verification**: Ping external hosts to verify internet access
- **IPv6 Support**: Optional IPv6 enablement and verification
- **DNS Checking**: Verify DNS resolution is working
- **Retry Logic**: Automatic retries for transient failures

### OS Configuration
- **Package Updates**: Safely update OS package lists
- **System Optimization**: Disable unnecessary services (wait-online)
- **Timezone**: Validate and set container timezone
- **SSH Setup**: Configure SSH daemon and keys

### Container Customization
- **MOTD**: Create custom login message
- **Auto-Login**: Optional passwordless root login
- **Update Script**: Register application update function
- **Customization Hooks**: Application-specific setup

## Function Categories

### 🔹 Core Functions
- `setting_up_container()` - Display setup message and set environment
- `network_check()` - Verify network connectivity
- `update_os()` - Update OS packages with retry logic
- `verb_ip6()` - Enable IPv6 (optional)

### 🔹 Configuration Functions
- `motd_ssh()` - Setup MOTD and SSH configuration
- `customize()` - Apply container customizations
- `cleanup_lxc()` - Final cleanup before completion

### 🔹 Utility Functions
- `create_update_script()` - Register application update function
- `set_timezone()` - Configure container timezone
- `disable_wait_online()` - Disable systemd-networkd-wait-online

## Execution Flow

```
Container Started
    ↓
source $FUNCTIONS_FILE_PATH
    ↓
setting_up_container()           ← Display "Setting up container..."
    ↓
network_check()                  ← Verify internet connectivity
    ↓
update_os()                      ← Update package lists
    ↓
[Application-Specific Installation]
    ↓
motd_ssh()                       ← Configure SSH/MOTD
customize()                      ← Apply customizations
    ↓
cleanup_lxc()                    ← Final cleanup
    ↓
Installation Complete
```

## Common Usage Patterns

### Basic Container Setup
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
setting_up_container
network_check
update_os

# ... application installation ...

motd_ssh
customize
cleanup_lxc
```

### With Optional IPv6
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
setting_up_container
verb_ip6  # Enable IPv6
network_check
update_os

# ... installation ...

motd_ssh
customize
cleanup_lxc
```

### With Custom Update Script
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
setting_up_container
network_check
update_os

# ... installation ...

# Register update function
function update_script() {
  # Update logic here
}
export -f update_script

motd_ssh
customize
cleanup_lxc
```

## Best Practices

### ✅ DO
- Call `setting_up_container()` at the start
- Check `network_check()` output before main installation
- Use `$STD` variable for silent operations
- Call `cleanup_lxc()` at the very end
- Test network connectivity before critical operations

### ❌ DON'T
- Skip network verification
- Assume internet is available
- Hardcode container paths
- Use `echo` instead of `msg_*` functions
- Forget to call cleanup at the end

## Environment Variables

### Available Variables
- `$FUNCTIONS_FILE_PATH` - Path to core functions (set by build.func)
- `$CTID` - Container ID number
- `$NSAPP` - Normalized application name (lowercase)
- `$APP` - Application display name
- `$STD` - Output suppression (`silent` or empty)
- `$VERBOSE` - Verbose output mode (`yes` or `no`)

### Setting Container Variables
```bash
CONTAINER_TIMEZONE="UTC"
CONTAINER_HOSTNAME="myapp-container"
CONTAINER_FQDN="myapp.example.com"
```

## Troubleshooting

### "Network check failed"
```bash
# Container may not have internet access
# Check:
ping 8.8.8.8           # External connectivity
nslookup example.com   # DNS resolution
ip route show          # Routing table
```

### "Package update failed"
```bash
# APT may be locked by another process
ps aux | grep apt      # Check for running apt
# Or wait for existing apt to finish
sleep 30
update_os
```

### "Cannot source functions"
```bash
# $FUNCTIONS_FILE_PATH may not be set
# This variable is set by build.func before running install script
# If missing, the install script was not called properly
```

## Related Documentation

- **[tools.func/](../tools.func/)** - Package and tool installation
- **[core.func/](../core.func/)** - Utility functions and messaging
- **[error_handler.func/](../error_handler.func/)** - Error handling
- **[alpine-install.func/](../alpine-install.func/)** - Alpine-specific setup
- **[UPDATED_APP-install.md](../../UPDATED_APP-install.md)** - Application script guide

## Recent Updates

### Version 2.0 (Dec 2025)
- ✅ Improved network connectivity checks
- ✅ Enhanced OS update error handling
- ✅ Added IPv6 support with verb_ip6()
- ✅ Better timezone validation
- ✅ Streamlined cleanup procedures

---

**Last Updated**: December 2025
**Maintainers**: community-scripts team
**License**: MIT
