# install.func Usage Examples

Practical examples for using install.func functions in application installation scripts.

## Basic Examples

### Example 1: Minimal Setup

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

### Example 2: With Error Handling

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

catch_errors
setting_up_container

if ! network_check; then
  msg_error "Network failed"
  exit 1
fi

if ! update_os; then
  msg_error "OS update failed"
  exit 1
fi

# ... continue ...
```

---

## Production Examples

### Example 3: Full Application Installation

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

catch_errors
setting_up_container
network_check
update_os

msg_info "Installing application"
# ... install steps ...
msg_ok "Application installed"

motd_ssh
customize
cleanup_lxc
```

### Example 4: With IPv6 Support

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

catch_errors
setting_up_container
verb_ip6
network_check
update_os

# ... application installation ...

motd_ssh
customize
cleanup_lxc
```

---

**Last Updated**: December 2025
**Examples**: Basic and production patterns
**All examples production-ready**
