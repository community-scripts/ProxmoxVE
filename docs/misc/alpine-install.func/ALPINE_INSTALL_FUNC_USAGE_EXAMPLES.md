# alpine-install.func Usage Examples

Basic examples for Alpine container installation.

### Example: Basic Alpine Setup

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
update_os

# Install Alpine packages
apk add --no-cache curl wget git

motd_ssh
customize
cleanup_lxc
```

---

**Last Updated**: December 2025
