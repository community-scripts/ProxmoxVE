# build.func Documentation

## Overview

This directory contains comprehensive documentation for the `build.func` script, which is the core orchestration script for Proxmox LXC container creation in the Community Scripts project.

## Documentation Files

### 📊 [BUILD_FUNC_FLOWCHART.md](./BUILD_FUNC_FLOWCHART.md)
Visual ASCII flowchart showing the main execution flow, decision trees, and key decision points in the build.func script.

**Contents:**
- Main execution flow diagram
- Installation mode selection flows
- Storage selection workflow
- GPU passthrough decision logic
- Variable precedence chain
- Error handling flow
- Integration points

### 🔧 [BUILD_FUNC_ENVIRONMENT_VARIABLES.md](./BUILD_FUNC_ENVIRONMENT_VARIABLES.md)
Complete reference of all environment variables used in build.func, organized by category and usage context.

**Contents:**
- Core container variables
- Operating system variables
- Resource configuration variables
- Network configuration variables
- Storage configuration variables
- Feature flags
- GPU passthrough variables
- API and diagnostics variables
- Settings persistence variables
- Variable precedence chain
- Critical variables for non-interactive use
- Common variable combinations

### 📚 [BUILD_FUNC_FUNCTIONS_REFERENCE.md](./BUILD_FUNC_FUNCTIONS_REFERENCE.md)
Alphabetical function reference with detailed descriptions, parameters, dependencies, and usage information.

**Contents:**
- Initialization functions
- UI and menu functions
- Storage functions
- Container creation functions
- GPU and hardware functions
- Settings persistence functions
- Utility functions
- Function call flow
- Function dependencies
- Function usage examples
- Function error handling

### 🔄 [BUILD_FUNC_EXECUTION_FLOWS.md](./BUILD_FUNC_EXECUTION_FLOWS.md)
Detailed execution flows for different installation modes and scenarios, including variable precedence and decision trees.

**Contents:**
- Default install flow
- Advanced install flow
- My defaults flow
- App defaults flow
- Variable precedence chain
- Storage selection logic
- GPU passthrough flow
- Network configuration flow
- Container creation flow
- Error handling flows
- Integration flows
- Performance considerations

### 🏗️ [BUILD_FUNC_ARCHITECTURE.md](./BUILD_FUNC_ARCHITECTURE.md)
High-level architectural overview including module dependencies, data flow, integration points, and system architecture.

**Contents:**
- High-level architecture diagram
- Module dependencies
- Data flow architecture
- Integration architecture
- System architecture components
- User interface components
- Security architecture
- Performance architecture
- Deployment architecture
- Maintenance architecture
- Future architecture considerations

### 💡 [BUILD_FUNC_USAGE_EXAMPLES.md](./BUILD_FUNC_USAGE_EXAMPLES.md)
Practical usage examples covering common scenarios, CLI examples, and environment variable combinations.

**Contents:**
- Basic usage examples
- Silent/non-interactive examples
- Network configuration examples
- Storage configuration examples
- Feature configuration examples
- Settings persistence examples
- Error handling examples
- Integration examples
- Best practices

## Quick Start Guide

### For New Users
1. Start with [BUILD_FUNC_FLOWCHART.md](./BUILD_FUNC_FLOWCHART.md) to understand the overall flow
2. Review [BUILD_FUNC_ENVIRONMENT_VARIABLES.md](./BUILD_FUNC_ENVIRONMENT_VARIABLES.md) for configuration options
3. Follow examples in [BUILD_FUNC_USAGE_EXAMPLES.md](./BUILD_FUNC_USAGE_EXAMPLES.md)

### For Developers
1. Read [BUILD_FUNC_ARCHITECTURE.md](./BUILD_FUNC_ARCHITECTURE.md) for system overview
2. Study [BUILD_FUNC_FUNCTIONS_REFERENCE.md](./BUILD_FUNC_FUNCTIONS_REFERENCE.md) for function details
3. Review [BUILD_FUNC_EXECUTION_FLOWS.md](./BUILD_FUNC_EXECUTION_FLOWS.md) for implementation details

### For System Administrators
1. Focus on [BUILD_FUNC_USAGE_EXAMPLES.md](./BUILD_FUNC_USAGE_EXAMPLES.md) for deployment scenarios
2. Review [BUILD_FUNC_ENVIRONMENT_VARIABLES.md](./BUILD_FUNC_ENVIRONMENT_VARIABLES.md) for configuration management
3. Check [BUILD_FUNC_ARCHITECTURE.md](./BUILD_FUNC_ARCHITECTURE.md) for security and performance considerations

## Key Concepts

### Variable Precedence
Variables are resolved in this order (highest to lowest priority):
1. Hard environment variables (set before script execution)
2. App-specific .vars file (`/usr/local/community-scripts/defaults/<app>.vars`)
3. Global default.vars file (`/usr/local/community-scripts/default.vars`)
4. Built-in defaults (set in `base_settings()` function)

### Installation Modes
- **Default Install**: Uses built-in defaults, minimal prompts
- **Advanced Install**: Full interactive configuration via whiptail
- **My Defaults**: Loads from global default.vars file
- **App Defaults**: Loads from app-specific .vars file

### Storage Selection Logic
1. If only 1 storage exists for content type → auto-select
2. If preselected via environment variables → validate and use
3. Otherwise → prompt user via whiptail

### GPU Passthrough Flow
1. Detect hardware (Intel/AMD/NVIDIA)
2. Check if app is in GPU_APPS list OR container is privileged
3. Auto-select if single GPU type, prompt if multiple
4. Configure `/etc/pve/lxc/<ctid>.conf` with proper device entries
5. Fix GIDs post-creation to match container's video/render groups

## Common Use Cases

### Basic Container Creation
```bash
export APP="plex"
export CTID="100"
export var_hostname="plex-server"
export var_os="debian"
export var_version="12"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.100"
export var_template_storage="local"
export var_container_storage="local"

source build.func
```

### GPU Passthrough
```bash
export APP="jellyfin"
export CTID="101"
export var_hostname="jellyfin-server"
export var_os="debian"
export var_version="12"
export var_cpu="8"
export var_ram="16384"
export var_disk="30"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.101"
export var_template_storage="local"
export var_container_storage="local"
export GPU_APPS="jellyfin"
export var_gpu="nvidia"
export ENABLE_PRIVILEGED="true"

source build.func
```

### Silent/Non-Interactive Deployment
```bash
#!/bin/bash
# Automated deployment
export APP="nginx"
export CTID="102"
export var_hostname="nginx-proxy"
export var_os="alpine"
export var_version="3.18"
export var_cpu="1"
export var_ram="512"
export var_disk="2"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.102"
export var_template_storage="local"
export var_container_storage="local"
export ENABLE_UNPRIVILEGED="true"

source build.func
```

## Troubleshooting

### Common Issues
1. **Container creation fails**: Check resource availability and configuration validity
2. **Storage errors**: Verify storage exists and supports required content types
3. **Network errors**: Validate network configuration and IP address availability
4. **GPU passthrough issues**: Check hardware detection and container privileges
5. **Permission errors**: Verify user permissions and container privileges

### Debug Mode
Enable verbose output for debugging:
```bash
export VERBOSE="true"
export DIAGNOSTICS="true"
source build.func
```

### Log Files
Check system logs for detailed error information:
- `/var/log/syslog`
- `/var/log/pve/lxc/<ctid>.log`
- Container-specific logs

## Contributing

When contributing to build.func documentation:
1. Update relevant documentation files
2. Add examples for new features
3. Update architecture diagrams if needed
4. Test all examples before submitting
5. Follow the existing documentation style

## Related Documentation

- [Main README](../../README.md) - Project overview
- [Installation Guide](../../install/) - Installation scripts
- [Container Templates](../../ct/) - Container templates
- [Tools](../../tools/) - Additional tools and utilities

## Support

For issues and questions:
1. Check this documentation first
2. Review the [troubleshooting section](#troubleshooting)
3. Check existing issues in the project repository
4. Create a new issue with detailed information

---

*Last updated: $(date)*
*Documentation version: 1.0*
