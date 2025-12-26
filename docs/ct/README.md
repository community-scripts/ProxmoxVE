# Container Scripts Documentation (/ct)

This directory contains comprehensive documentation for container creation scripts in the `/ct` directory.

## Overview

Container scripts (`ct/*.sh`) are the entry points for creating LXC containers in Proxmox VE. They run on the host and orchestrate the entire container creation process.

## Documentation Structure

Each script has standardized documentation following the project pattern.

## Key Resources

- **[DETAILED_GUIDE.md](DETAILED_GUIDE.md)** - Complete reference for creating ct scripts
- **[../contribution/README.md](../contribution/README.md)** - How to contribute
- **[../misc/build.func/](../misc/build.func/)** - Core orchestrator documentation

## Container Creation Flow

```
ct/AppName.sh (host-side)
    │
    ├─ Calls: build.func (orchestrator)
    │
    ├─ Variables: var_cpu, var_ram, var_disk, var_os
    │
    └─ Creates: LXC Container
                │
                └─ Runs: install/appname-install.sh (inside)
```

## Available Scripts

See `/ct` directory for all container creation scripts. Common examples:

- `pihole.sh` - Pi-hole DNS/DHCP server
- `docker.sh` - Docker container runtime
- `wallabag.sh` - Article reading & archiving
- `nextcloud.sh` - Private cloud storage
- `debian.sh` - Basic Debian container
- And 30+ more...

## Quick Start

To understand how to create a container script:

1. Read: [UPDATED_APP-ct.md](../UPDATED_APP-ct.md)
2. Study: A similar existing script in `/ct`
3. Copy template and customize
4. Test locally
5. Submit PR

## Contributing a New Container

1. Create `ct/myapp.sh`
2. Create `install/myapp-install.sh`
3. Follow template in [UPDATED_APP-ct.md](../UPDATED_APP-ct.md)
4. Test thoroughly
5. Submit PR with both files

## Common Tasks

- **Add new container application** → [CONTRIBUTION_GUIDE.md](../CONTRIBUTION_GUIDE.md)
- **Debug container creation** → [EXIT_CODES.md](../EXIT_CODES.md)
- **Understand build.func** → [misc/build.func/](../misc/build.func/)
- **Development mode debugging** → [DEV_MODE.md](../DEV_MODE.md)

---

**Last Updated**: December 2025
**Maintainers**: community-scripts team
