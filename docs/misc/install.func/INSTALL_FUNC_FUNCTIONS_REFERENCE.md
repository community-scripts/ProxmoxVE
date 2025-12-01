# install.func Functions Reference

Complete reference of all functions in install.func with detailed usage information.

## Function Index

- `setting_up_container()` - Initialize container setup
- `network_check()` - Verify network connectivity
- `update_os()` - Update OS packages
- `verb_ip6()` - Enable IPv6
- `motd_ssh()` - Configure SSH and MOTD
- `customize()` - Apply container customizations
- `cleanup_lxc()` - Final container cleanup

---

## Core Functions

### setting_up_container()

Display setup message and initialize container environment.

**Signature**:
```bash
setting_up_container
```

**Purpose**: Announce container initialization and set initial environment

**Usage**:
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
# Output: ⏳ Setting up container...
```

---

### network_check()

Verify network connectivity with automatic retry logic.

**Signature**:
```bash
network_check
```

**Purpose**: Ensure internet connectivity before critical operations

**Behavior**:
- Pings 8.8.8.8 (Google DNS)
- 3 attempts with 5-second delays
- Exits with error if all attempts fail

**Usage**:
```bash
network_check
# If no internet: Exits with error message
# If internet OK: Continues to next step
```

**Error Handling**:
```bash
if ! network_check; then
  msg_error "No internet connection"
  exit 1
fi
```

---

### update_os()

Update OS packages with error handling.

**Signature**:
```bash
update_os
```

**Purpose**: Prepare container with latest packages

**On Debian/Ubuntu**:
- Runs: `apt-get update && apt-get upgrade -y`

**On Alpine**:
- Runs: `apk update && apk upgrade`

**Usage**:
```bash
update_os
```

---

### verb_ip6()

Enable IPv6 support in container (optional).

**Signature**:
```bash
verb_ip6
```

**Purpose**: Enable IPv6 if needed for application

**Usage**:
```bash
verb_ip6              # Enable IPv6
network_check         # Verify connectivity with IPv6
```

---

### motd_ssh()

Configure SSH daemon and MOTD for container access.

**Signature**:
```bash
motd_ssh
```

**Purpose**: Setup SSH and create login message

**Configures**:
- SSH daemon startup and keys
- Custom MOTD displaying application access info
- SSH port and security settings

**Usage**:
```bash
motd_ssh
# SSH is now configured and application info is in MOTD
```

---

### customize()

Apply container customizations and final setup.

**Signature**:
```bash
customize
```

**Purpose**: Apply any remaining customizations

**Usage**:
```bash
customize
```

---

### cleanup_lxc()

Final cleanup and completion of installation.

**Signature**:
```bash
cleanup_lxc
```

**Purpose**: Remove temporary files and finalize installation

**Cleans**:
- Temporary installation files
- Package manager cache
- Log files from installation process

**Usage**:
```bash
cleanup_lxc
# Installation is now complete and ready
```

---

## Common Patterns

### Basic Installation Pattern

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

### With IPv6 Support

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
verb_ip6              # Enable IPv6
network_check
update_os

# ... application installation ...
```

### With Error Handling

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

catch_errors          # Setup error trapping
setting_up_container

if ! network_check; then
  msg_error "Network connectivity failed"
  exit 1
fi

update_os
```

---

**Last Updated**: December 2025
**Total Functions**: 7
**Maintained by**: community-scripts team
