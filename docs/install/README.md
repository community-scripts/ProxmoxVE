# Installation Scripts Documentation (/install)

This directory contains comprehensive documentation for installation scripts in the `/install` directory.

## Overview

Installation scripts (`install/*.sh`) run inside LXC containers and handle application-specific setup, configuration, and deployment.

## Documentation Structure

Each installation script category has documentation following the project pattern.

## Key Resources

- **[DETAILED_GUIDE.md](DETAILED_GUIDE.md)** - Complete reference for creating install scripts
- **[../contribution/README.md](../contribution/README.md)** - How to contribute
- **[../misc/install.func/](../misc/install.func/)** - Installation workflow documentation
- **[../misc/tools.func/](../misc/tools.func/)** - Package installation documentation

## Installation Script Flow

```
install/appname-install.sh (container-side)
    │
    ├─ Sources: $FUNCTIONS_FILE_PATH
    │  ├─ core.func (messaging)
    │  ├─ error_handler.func (error handling)
    │  ├─ install.func (setup)
    │  └─ tools.func (packages & tools)
    │
    ├─ 10-Phase Installation:
    │  1. OS Setup
    │  2. Base Dependencies
    │  3. Tool Setup
    │  4. Application Download
    │  5. Configuration
    │  6. Database Setup
    │  7. Permissions
    │  8. Services
    │  9. Version Tracking
    │  10. Final Cleanup
    │
    └─ Result: Application ready
```

## Available Installation Scripts

See `/install` directory for all installation scripts. Examples:

- `pihole-install.sh` - Pi-hole installation
- `docker-install.sh` - Docker installation
- `wallabag-install.sh` - Wallabag setup
- `nextcloud-install.sh` - Nextcloud deployment
- `debian-install.sh` - Base Debian setup
- And 30+ more...

## Quick Start

To understand how to create an installation script:

1. Read: [UPDATED_APP-install.md](../UPDATED_APP-install.md)
2. Study: A similar existing script in `/install`
3. Copy template and customize
4. Test in container
5. Submit PR

## 10-Phase Installation Pattern

Every installation script follows this structure:

### Phase 1: OS Setup
```bash
setting_up_container
network_check
update_os
```

### Phase 2: Base Dependencies
```bash
pkg_update
pkg_install curl wget git
```

### Phase 3: Tool Setup
```bash
setup_nodejs "20"
setup_php "8.3"
setup_mariadb "11"
```

### Phase 4: Application Download
```bash
git clone https://github.com/user/app /opt/app
cd /opt/app
```

### Phase 5: Configuration
```bash
# Create .env files, config files, etc.
cat > .env <<EOF
SETTING=value
EOF
```

### Phase 6: Database Setup
```bash
# Create databases, users, etc.
mysql -e "CREATE DATABASE appdb"
```

### Phase 7: Permissions
```bash
chown -R appuser:appgroup /opt/app
chmod -R 755 /opt/app
```

### Phase 8: Services
```bash
systemctl enable app
systemctl start app
```

### Phase 9: Version Tracking
```bash
echo "1.0.0" > /opt/app_version.txt
```

### Phase 10: Final Cleanup
```bash
motd_ssh
customize
cleanup_lxc
```

## Contributing an Installation Script

1. Create `ct/myapp.sh` (host script)
2. Create `install/myapp-install.sh` (container script)
3. Follow 10-phase pattern in [UPDATED_APP-install.md](../UPDATED_APP-install.md)
4. Test in actual container
5. Submit PR with both files

## Common Tasks

- **Create new installation script** → [UPDATED_APP-install.md](../UPDATED_APP-install.md)
- **Install Node.js/PHP/Database** → [misc/tools.func/](../misc/tools.func/)
- **Setup Alpine container** → [misc/alpine-install.func/](../misc/alpine-install.func/)
- **Debug installation errors** → [EXIT_CODES.md](../EXIT_CODES.md)
- **Use dev mode** → [DEV_MODE.md](../DEV_MODE.md)

## Alpine vs Debian

- **Debian-based** → Use `tools.func`, `install.func`, `systemctl`
- **Alpine-based** → Use `alpine-tools.func`, `alpine-install.func`, `rc-service`

---

**Last Updated**: December 2025
**Maintainers**: community-scripts team
