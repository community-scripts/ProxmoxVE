# build.func Environment Variables Reference

## Overview

This document provides a comprehensive reference of all environment variables used in `build.func`, organized by category and usage context.

## Variable Categories

### Core Container Variables

| Variable | Description | Default | Set In | Used In |
|----------|-------------|---------|---------|---------|
| `APP` | Application name (e.g., "plex", "nextcloud") | - | Environment | Throughout |
| `NSAPP` | Namespace application name | `$APP` | Environment | Throughout |
| `CTID` | Container ID | - | Environment | Container creation |
| `CT_TYPE` | Container type ("install" or "update") | "install" | Environment | Entry point |
| `CT_NAME` | Container name | `$APP` | Environment | Container creation |

### Operating System Variables

| Variable | Description | Default | Set In | Used In |
|----------|-------------|---------|---------|---------|
| `var_os` | Operating system selection | "debian" | base_settings() | OS selection |
| `var_version` | OS version | "12" | base_settings() | Template selection |
| `var_template` | Template name | Auto-generated | base_settings() | Template download |

### Resource Configuration Variables

| Variable | Description | Default | Set In | Used In |
|----------|-------------|---------|---------|---------|
| `var_cpu` | CPU cores | "2" | base_settings() | Container creation |
| `var_ram` | RAM in MB | "2048" | base_settings() | Container creation |
| `var_disk` | Disk size in GB | "8" | base_settings() | Container creation |
| `DISK_SIZE` | Disk size (alternative) | `$var_disk` | Environment | Container creation |
| `CORE_COUNT` | CPU cores (alternative) | `$var_cpu` | Environment | Container creation |
| `RAM_SIZE` | RAM size (alternative) | `$var_ram` | Environment | Container creation |

### Network Configuration Variables

| Variable | Description | Default | Set In | Used In |
|----------|-------------|---------|---------|---------|
| `var_net` | Network interface | "vmbr0" | base_settings() | Network config |
| `var_bridge` | Bridge interface | "vmbr0" | base_settings() | Network config |
| `var_gateway` | Gateway IP | "192.168.1.1" | base_settings() | Network config |
| `var_ip` | Container IP address | - | User input | Network config |
| `var_ipv6` | IPv6 address | - | User input | Network config |
| `var_vlan` | VLAN ID | - | User input | Network config |
| `var_mtu` | MTU size | "1500" | base_settings() | Network config |
| `var_mac` | MAC address | Auto-generated | base_settings() | Network config |
| `NET` | Network interface (alternative) | `$var_net` | Environment | Network config |
| `BRG` | Bridge interface (alternative) | `$var_bridge` | Environment | Network config |
| `GATE` | Gateway IP (alternative) | `$var_gateway` | Environment | Network config |
| `IPV6_METHOD` | IPv6 configuration method | "none" | Environment | Network config |
| `VLAN` | VLAN ID (alternative) | `$var_vlan` | Environment | Network config |
| `MTU` | MTU size (alternative) | `$var_mtu` | Environment | Network config |
| `MAC` | MAC address (alternative) | `$var_mac` | Environment | Network config |

### Storage Configuration Variables

| Variable | Description | Default | Set In | Used In |
|----------|-------------|---------|---------|---------|
| `var_template_storage` | Storage for templates | - | select_storage() | Template storage |
| `var_container_storage` | Storage for container disks | - | select_storage() | Container storage |
| `TEMPLATE_STORAGE` | Template storage (alternative) | `$var_template_storage` | Environment | Template storage |
| `CONTAINER_STORAGE` | Container storage (alternative) | `$var_container_storage` | Environment | Container storage |

### Feature Flags

| Variable | Description | Default | Set In | Used In |
|----------|-------------|---------|---------|---------|
| `ENABLE_FUSE` | Enable FUSE support | "true" | base_settings() | Container features |
| `ENABLE_TUN` | Enable TUN/TAP support | "true" | base_settings() | Container features |
| `ENABLE_KEYCTL` | Enable keyctl support | "true" | base_settings() | Container features |
| `ENABLE_MOUNT` | Enable mount support | "true" | base_settings() | Container features |
| `ENABLE_NESTING` | Enable nesting support | "false" | base_settings() | Container features |
| `ENABLE_PRIVILEGED` | Enable privileged mode | "false" | base_settings() | Container features |
| `ENABLE_UNPRIVILEGED` | Enable unprivileged mode | "true" | base_settings() | Container features |
| `VERBOSE` | Enable verbose output | "false" | Environment | Logging |
| `SSH` | Enable SSH key provisioning | "true" | base_settings() | SSH setup |

### GPU Passthrough Variables

| Variable | Description | Default | Set In | Used In |
|----------|-------------|---------|---------|---------|
| `GPU_APPS` | List of apps that support GPU | - | Environment | GPU detection |
| `var_gpu` | GPU selection | - | User input | GPU passthrough |
| `var_gpu_type` | GPU type (intel/amd/nvidia) | - | detect_gpu_devices() | GPU passthrough |
| `var_gpu_devices` | GPU device list | - | detect_gpu_devices() | GPU passthrough |

### API and Diagnostics Variables

| Variable | Description | Default | Set In | Used In |
|----------|-------------|---------|---------|---------|
| `DIAGNOSTICS` | Enable diagnostics mode | "false" | Environment | Diagnostics |
| `METHOD` | Installation method | "install" | Environment | Installation flow |
| `RANDOM_UUID` | Random UUID for tracking | - | Environment | Logging |
| `API_TOKEN` | Proxmox API token | - | Environment | API calls |
| `API_USER` | Proxmox API user | - | Environment | API calls |

### Settings Persistence Variables

| Variable | Description | Default | Set In | Used In |
|----------|-------------|---------|---------|---------|
| `SAVE_DEFAULTS` | Save settings as defaults | "false" | User input | Settings persistence |
| `SAVE_APP_DEFAULTS` | Save app-specific defaults | "false" | User input | Settings persistence |
| `DEFAULT_VARS_FILE` | Path to default.vars | "/usr/local/community-scripts/default.vars" | Environment | Settings persistence |
| `APP_DEFAULTS_FILE` | Path to app.vars | "/usr/local/community-scripts/defaults/$APP.vars" | Environment | Settings persistence |

## Variable Precedence Chain

Variables are resolved in the following order (highest to lowest priority):

1. **Hard Environment Variables**: Set before script execution
2. **App-specific .vars file**: `/usr/local/community-scripts/defaults/<app>.vars`
3. **Global default.vars file**: `/usr/local/community-scripts/default.vars`
4. **Built-in defaults**: Set in `base_settings()` function

## Critical Variables for Non-Interactive Use

For silent/non-interactive execution, these variables must be set:

```bash
# Core container settings
export APP="plex"
export CTID="100"
export var_hostname="plex-server"

# OS selection
export var_os="debian"
export var_version="12"

# Resource allocation
export var_cpu="4"
export var_ram="4096"
export var_disk="20"

# Network configuration
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.100"

# Storage selection
export var_template_storage="local"
export var_container_storage="local"

# Feature flags
export ENABLE_FUSE="true"
export ENABLE_TUN="true"
export SSH="true"
```

## Environment Variable Usage Patterns

### 1. Container Creation
```bash
# Basic container creation
export APP="nextcloud"
export CTID="101"
export var_hostname="nextcloud-server"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.101"
export var_template_storage="local"
export var_container_storage="local"
```

### 2. GPU Passthrough
```bash
# Enable GPU passthrough
export GPU_APPS="plex,jellyfin,emby"
export var_gpu="intel"
export ENABLE_PRIVILEGED="true"
```

### 3. Advanced Network Configuration
```bash
# VLAN and IPv6 configuration
export var_vlan="100"
export var_ipv6="2001:db8::100"
export IPV6_METHOD="static"
export var_mtu="9000"
```

### 4. Storage Configuration
```bash
# Custom storage locations
export var_template_storage="nfs-storage"
export var_container_storage="ssd-storage"
```

## Variable Validation

The script validates variables at several points:

1. **Container ID validation**: Must be unique and within valid range
2. **IP address validation**: Must be valid IPv4/IPv6 format
3. **Storage validation**: Must exist and support required content types
4. **Resource validation**: Must be within reasonable limits
5. **Network validation**: Must be valid network configuration

## Common Variable Combinations

### Development Container
```bash
export APP="dev-container"
export CTID="200"
export var_hostname="dev-server"
export var_os="ubuntu"
export var_version="22.04"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"
export ENABLE_NESTING="true"
export ENABLE_PRIVILEGED="true"
```

### Media Server with GPU
```bash
export APP="plex"
export CTID="300"
export var_hostname="plex-server"
export var_os="debian"
export var_version="12"
export var_cpu="6"
export var_ram="8192"
export var_disk="50"
export GPU_APPS="plex"
export var_gpu="nvidia"
export ENABLE_PRIVILEGED="true"
```

### Lightweight Service
```bash
export APP="nginx"
export CTID="400"
export var_hostname="nginx-proxy"
export var_os="alpine"
export var_version="3.18"
export var_cpu="1"
export var_ram="512"
export var_disk="2"
export ENABLE_UNPRIVILEGED="true"
```
