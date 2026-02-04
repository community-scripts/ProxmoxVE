# alpine-tools.func Usage Examples

Examples for Alpine tool installation.

### Example: Alpine Setup with Tools

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

apk_update
setup_nodejs "20"
setup_php "8.3"
setup_mariadb "11"
```

---

**Last Updated**: December 2025
