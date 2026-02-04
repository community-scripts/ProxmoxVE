# Tools & Add-ons Documentation (/tools)

This directory contains comprehensive documentation for tools, utilities, and add-ons in the `/tools` directory.

## Overview

The `/tools` directory contains:
- **Proxmox management tools** - Helper scripts for Proxmox administration
- **Proxmox VE add-ons** - Extensions and integrations
- **Utility scripts** - General-purpose automation tools

## Documentation Structure

Tools documentation focuses on purpose, usage, and integration with the main ecosystem.

## Available Tools

The `/tools` directory structure includes:

### `/tools/pve/`
Proxmox VE management and administration tools:
- Container management utilities
- VM management helpers
- Storage management tools
- Network configuration tools
- Backup and recovery utilities

### `/tools/addon/`
Proxmox add-ons and extensions:
- Web UI enhancements
- API extensions
- Integration modules
- Custom scripts

### `/tools/headers/`
ASCII art headers and templates for scripts.

## Common Tools & Scripts

Examples of tools available:

- **Container management** - Batch operations on containers
- **VM provisioning** - Automated VM setup
- **Backup automation** - Scheduled backups
- **Monitoring integration** - Connect to monitoring systems
- **Configuration management** - Infrastructure as code
- **Reporting tools** - Generate reports and statistics

## Integration Points

Tools integrate with:
- **build.func** - Main container orchestrator
- **core.func** - Utility functions
- **error_handler.func** - Error handling
- **tools.func** - Package installation

## Contributing Tools

To contribute a new tool:

1. Place script in appropriate `/tools/` subdirectory
2. Follow project standards:
   - Use `#!/usr/bin/env bash`
   - Source build.func if needed
   - Handle errors with error_handler.func
3. Document usage in script header comments
4. Submit PR

## Common Tasks

- **Create Proxmox management tool** → Study existing tools
- **Create add-on** → Follow add-on guidelines
- **Integration** → Use build.func and core.func
- **Error handling** → Use error_handler.func

---

**Last Updated**: December 2025
**Maintainers**: community-scripts team
