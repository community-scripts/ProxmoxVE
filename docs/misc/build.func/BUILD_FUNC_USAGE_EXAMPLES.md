# build.func Usage Examples

## Overview

This document provides practical usage examples for `build.func`, covering common scenarios, CLI examples, and environment variable combinations.

## Basic Usage Examples

### 1. Simple Container Creation

**Scenario**: Create a basic Plex media server container

```bash
# Set basic environment variables
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

# Execute build.func
source build.func
```

**Expected Output**:
```
Creating Plex container...
Container ID: 100
Hostname: plex-server
OS: Debian 12
Resources: 4 CPU, 4GB RAM, 20GB Disk
Network: 192.168.1.100/24
Container created successfully!
```

### 2. Advanced Configuration

**Scenario**: Create a Nextcloud container with custom settings

```bash
# Set advanced environment variables
export APP="nextcloud"
export CTID="101"
export var_hostname="nextcloud-server"
export var_os="ubuntu"
export var_version="22.04"
export var_cpu="6"
export var_ram="8192"
export var_disk="50"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.101"
export var_vlan="100"
export var_mtu="9000"
export var_template_storage="ssd-storage"
export var_container_storage="ssd-storage"
export var_fuse="yes"
export var_tun="yes"
export SSH="true"

# Execute build.func
source build.func
```

### 3. GPU Passthrough Configuration

**Scenario**: Create a Jellyfin container with NVIDIA GPU passthrough

```bash
# Set GPU passthrough variables
export APP="jellyfin"
export CTID="102"
export var_hostname="jellyfin-server"
export var_os="debian"
export var_version="12"
export var_cpu="8"
export var_ram="16384"
export var_disk="30"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.102"
export var_template_storage="local"
export var_container_storage="local"
export GPU_APPS="jellyfin"
export var_gpu="nvidia"
export ENABLE_PRIVILEGED="true"
export ENABLE_FUSE="true"
export ENABLE_TUN="true"

# Execute build.func
source build.func
```

## Silent/Non-Interactive Examples

### 1. Automated Deployment

**Scenario**: Deploy multiple containers without user interaction

```bash
#!/bin/bash
# Automated deployment script

# Function to create container
create_container() {
    local app=$1
    local ctid=$2
    local ip=$3

    export APP="$app"
    export CTID="$ctid"
    export var_hostname="${app}-server"
    export var_os="debian"
    export var_version="12"
    export var_cpu="2"
    export var_ram="2048"
    export var_disk="10"
    export var_net="vmbr0"
    export var_gateway="192.168.1.1"
    export var_ip="$ip"
    export var_template_storage="local"
    export var_container_storage="local"
    export ENABLE_FUSE="true"
    export ENABLE_TUN="true"
    export SSH="true"

    source build.func
}

# Create multiple containers
create_container "plex" "100" "192.168.1.100"
create_container "nextcloud" "101" "192.168.1.101"
create_container "nginx" "102" "192.168.1.102"
```

### 2. Development Environment Setup

**Scenario**: Create development containers with specific configurations

```bash
#!/bin/bash
# Development environment setup

# Development container configuration
export APP="dev-container"
export CTID="200"
export var_hostname="dev-server"
export var_os="ubuntu"
export var_version="22.04"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.200"
export var_template_storage="local"
export var_container_storage="local"
export ENABLE_NESTING="true"
export ENABLE_PRIVILEGED="true"
export ENABLE_FUSE="true"
export ENABLE_TUN="true"
export SSH="true"

# Execute build.func
source build.func
```

## Network Configuration Examples

### 1. VLAN Configuration

**Scenario**: Create container with VLAN support

```bash
# VLAN configuration
export APP="web-server"
export CTID="300"
export var_hostname="web-server"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.100.1"
export var_ip="192.168.100.100"
export var_vlan="100"
export var_mtu="1500"
export var_template_storage="local"
export var_container_storage="local"

source build.func
```

### 2. IPv6 Configuration

**Scenario**: Create container with IPv6 support

```bash
# IPv6 configuration
export APP="ipv6-server"
export CTID="301"
export var_hostname="ipv6-server"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.101"
export var_ipv6="2001:db8::101"
export IPV6_METHOD="static"
export var_template_storage="local"
export var_container_storage="local"

source build.func
```

## Storage Configuration Examples

### 1. Custom Storage Locations

**Scenario**: Use different storage for templates and containers

```bash
# Custom storage configuration
export APP="storage-test"
export CTID="400"
export var_hostname="storage-test"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.140"
export var_template_storage="nfs-storage"
export var_container_storage="ssd-storage"

source build.func
```

### 2. High-Performance Storage

**Scenario**: Use high-performance storage for resource-intensive applications

```bash
# High-performance storage configuration
export APP="database-server"
export CTID="401"
export var_hostname="database-server"
export var_os="debian"
export var_version="12"
export var_cpu="8"
export var_ram="16384"
export var_disk="100"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.141"
export var_template_storage="nvme-storage"
export var_container_storage="nvme-storage"

source build.func
```

## Feature Configuration Examples

### 1. Privileged Container

**Scenario**: Create privileged container for system-level access

```bash
# Privileged container configuration
export APP="system-container"
export CTID="500"
export var_hostname="system-container"
export var_os="debian"
export var_version="12"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.150"
export var_template_storage="local"
export var_container_storage="local"
export ENABLE_PRIVILEGED="true"
export ENABLE_FUSE="true"
export ENABLE_TUN="true"
export ENABLE_KEYCTL="true"
export ENABLE_MOUNT="true"

source build.func
```

### 2. Unprivileged Container

**Scenario**: Create secure unprivileged container

```bash
# Unprivileged container configuration
export APP="secure-container"
export CTID="501"
export var_hostname="secure-container"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.151"
export var_template_storage="local"
export var_container_storage="local"
export ENABLE_UNPRIVILEGED="true"
export ENABLE_FUSE="true"
export ENABLE_TUN="true"

source build.func
```

## Settings Persistence Examples

### 1. Save Global Defaults

**Scenario**: Save current settings as global defaults

```bash
# Save global defaults
export APP="default-test"
export CTID="600"
export var_hostname="default-test"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.160"
export var_template_storage="local"
export var_container_storage="local"
export SAVE_DEFAULTS="true"

source build.func
```

### 2. Save App-Specific Defaults

**Scenario**: Save settings as app-specific defaults

```bash
# Save app-specific defaults
export APP="plex"
export CTID="601"
export var_hostname="plex-server"
export var_os="debian"
export var_version="12"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.161"
export var_template_storage="local"
export var_container_storage="local"
export SAVE_APP_DEFAULTS="true"

source build.func
```

## Error Handling Examples

### 1. Validation Error Handling

**Scenario**: Handle configuration validation errors

```bash
#!/bin/bash
# Error handling example

# Set invalid configuration
export APP="error-test"
export CTID="700"
export var_hostname="error-test"
export var_os="invalid-os"
export var_version="invalid-version"
export var_cpu="invalid-cpu"
export var_ram="invalid-ram"
export var_disk="invalid-disk"
export var_net="invalid-network"
export var_gateway="invalid-gateway"
export var_ip="invalid-ip"

# Execute with error handling
if source build.func; then
    echo "Container created successfully!"
else
    echo "Error: Container creation failed!"
    echo "Please check your configuration and try again."
fi
```

### 2. Storage Error Handling

**Scenario**: Handle storage selection errors

```bash
#!/bin/bash
# Storage error handling

# Set invalid storage
export APP="storage-error-test"
export CTID="701"
export var_hostname="storage-error-test"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.170"
export var_template_storage="nonexistent-storage"
export var_container_storage="nonexistent-storage"

# Execute with error handling
if source build.func; then
    echo "Container created successfully!"
else
    echo "Error: Storage not available!"
    echo "Please check available storage and try again."
fi
```

## Integration Examples

### 1. With Install Scripts

**Scenario**: Integrate with application install scripts

```bash
#!/bin/bash
# Integration with install scripts

# Create container
export APP="plex"
export CTID="800"
export var_hostname="plex-server"
export var_os="debian"
export var_version="12"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.180"
export var_template_storage="local"
export var_container_storage="local"

# Create container
source build.func

# Run install script
if [ -f "plex-install.sh" ]; then
    source plex-install.sh
else
    echo "Install script not found!"
fi
```

### 2. With Monitoring

**Scenario**: Integrate with monitoring systems

```bash
#!/bin/bash
# Monitoring integration

# Create container with monitoring
export APP="monitored-app"
export CTID="801"
export var_hostname="monitored-app"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.181"
export var_template_storage="local"
export var_container_storage="local"
export DIAGNOSTICS="true"

# Create container
source build.func

# Set up monitoring
if [ -f "monitoring-setup.sh" ]; then
    source monitoring-setup.sh
fi
```

## Best Practices

### 1. Environment Variable Management

```bash
#!/bin/bash
# Best practice: Environment variable management

# Set configuration file
CONFIG_FILE="/etc/build.func.conf"

# Load configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Set required variables
export APP="${APP:-plex}"
export CTID="${CTID:-100}"
export var_hostname="${var_hostname:-plex-server}"
export var_os="${var_os:-debian}"
export var_version="${var_version:-12}"
export var_cpu="${var_cpu:-2}"
export var_ram="${var_ram:-2048}"
export var_disk="${var_disk:-10}"
export var_net="${var_net:-vmbr0}"
export var_gateway="${var_gateway:-192.168.1.1}"
export var_ip="${var_ip:-192.168.1.100}"
export var_template_storage="${var_template_storage:-local}"
export var_container_storage="${var_container_storage:-local}"

# Execute build.func
source build.func
```

### 2. Error Handling and Logging

```bash
#!/bin/bash
# Best practice: Error handling and logging

# Set log file
LOG_FILE="/var/log/build.func.log"

# Function to log messages
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Function to create container with error handling
create_container() {
    local app=$1
    local ctid=$2

    log_message "Starting container creation for $app (ID: $ctid)"

    # Set variables
    export APP="$app"
    export CTID="$ctid"
    export var_hostname="${app}-server"
    export var_os="debian"
    export var_version="12"
    export var_cpu="2"
    export var_ram="2048"
    export var_disk="10"
    export var_net="vmbr0"
    export var_gateway="192.168.1.1"
    export var_ip="192.168.1.$ctid"
    export var_template_storage="local"
    export var_container_storage="local"

    # Create container
    if source build.func; then
        log_message "Container $app created successfully (ID: $ctid)"
        return 0
    else
        log_message "Error: Failed to create container $app (ID: $ctid)"
        return 1
    fi
}

# Create containers
create_container "plex" "100"
create_container "nextcloud" "101"
create_container "nginx" "102"
```
