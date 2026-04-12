# api.func Usage Examples

## Overview

This document provides practical usage examples for `api.func` functions, covering common scenarios, integration patterns, and best practices.

## Basic API Setup

### Standard API Initialization

```bash
#!/usr/bin/env bash
# Standard API setup for LXC containers

source api.func

# Set up diagnostic reporting
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# Set container parameters
export CT_TYPE=1
export DISK_SIZE=8
export CORE_COUNT=2
export RAM_SIZE=2048
export var_os="debian"
export var_version="12"
export NSAPP="plex"
export METHOD="install"

# Report installation start
post_to_api

# Your installation code here
# ... installation logic ...

# Report completion
if [[ $? -eq 0 ]]; then
    post_update_to_api "success" 0
else
    post_update_to_api "failed" $?
fi
```

### VM API Setup

```bash
#!/usr/bin/env bash
# API setup for VMs

source api.func

# Create diagnostics file for VM
mkdir -p /usr/local/community-scripts
echo "DIAGNOSTICS=yes" > /usr/local/community-scripts/diagnostics

# Set up VM parameters
export RANDOM_UUID="$(uuidgen)"
export DISK_SIZE="20G"
export CORE_COUNT=4
export RAM_SIZE=4096
export var_os="ubuntu"
export var_version="22.04"
export NSAPP="nextcloud"
export METHOD="install"

# Report VM installation start
post_to_api_vm

# Your VM installation code here
# ... VM creation logic ...

# Report completion
post_update_to_api "success" 0
```

## Error Description Examples

### Basic Error Explanation

```bash
#!/usr/bin/env bash
source api.func

# Explain common error codes
echo "Error 0: '$(get_error_description 0)'"
echo "Error 1: $(get_error_description 1)"
echo "Error 127: $(get_error_description 127)"
echo "Error 200: $(get_error_description 200)"
echo "Error 255: $(get_error_description 255)"
```

### Error Code Testing

```bash
#!/usr/bin/env bash
source api.func

# Test all error codes
test_error_codes() {
    local codes=(0 1 2 127 128 130 137 139 143 200 203 205 255)

    for code in "${codes[@]}"; do
        echo "Code $code: $(get_error_description $code)"
    done
}

test_error_codes
```

### Error Handling with Descriptions

```bash
#!/usr/bin/env bash
source api.func

# Function with error handling
run_command_with_error_handling() {
    local command="$1"
    local description="$2"

    echo "Running: $description"

    if $command; then
        echo "Success: $description"
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "Error $exit_code: $error_msg"
        return $exit_code
    fi
}

# Usage
run_command_with_error_handling "apt-get update" "Package list update"
run_command_with_error_handling "nonexistent_command" "Test command"
```

## API Communication Examples

### LXC Installation Reporting

```bash
#!/usr/bin/env bash
source api.func

# Complete LXC installation with API reporting
install_lxc_with_reporting() {
    local app="$1"
    local ctid="$2"

    # Set up API reporting
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export CT_TYPE=1
    export DISK_SIZE=10
    export CORE_COUNT=2
    export RAM_SIZE=2048
    export var_os="debian"
    export var_version="12"
    export NSAPP="$app"
    export METHOD="install"

    # Report installation start
    post_to_api

    # Installation process
    echo "Installing $app container (ID: $ctid)..."

    # Simulate installation
    sleep 2

    # Check if installation succeeded
    if [[ $? -eq 0 ]]; then
        echo "Installation completed successfully"
        post_update_to_api "success" 0
        return 0
    else
        echo "Installation failed"
        post_update_to_api "failed" $?
        return 1
    fi
}

# Install multiple containers
install_lxc_with_reporting "plex" "100"
install_lxc_with_reporting "nextcloud" "101"
install_lxc_with_reporting "nginx" "102"
```

### VM Installation Reporting

```bash
#!/usr/bin/env bash
source api.func

# Complete VM installation with API reporting
install_vm_with_reporting() {
    local app="$1"
    local vmid="$2"

    # Create diagnostics file
    mkdir -p /usr/local/community-scripts
    echo "DIAGNOSTICS=yes" > /usr/local/community-scripts/diagnostics

    # Set up API reporting
    export RANDOM_UUID="$(uuidgen)"
    export DISK_SIZE="20G"
    export CORE_COUNT=4
    export RAM_SIZE=4096
    export var_os="ubuntu"
    export var_version="22.04"
    export NSAPP="$app"
    export METHOD="install"

    # Report VM installation start
    post_to_api_vm

    # VM installation process
    echo "Installing $app VM (ID: $vmid)..."

    # Simulate VM creation
    sleep 3

    # Check if VM creation succeeded
    if [[ $? -eq 0 ]]; then
        echo "VM installation completed successfully"
        post_update_to_api "success" 0
        return 0
    else
        echo "VM installation failed"
        post_update_to_api "failed" $?
        return 1
    fi
}

# Install multiple VMs
install_vm_with_reporting "nextcloud" "200"
install_vm_with_reporting "wordpress" "201"
```

## Status Update Examples

### Success Reporting

```bash
#!/usr/bin/env bash
source api.func

# Report successful installation
report_success() {
    local operation="$1"

    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"

    echo "Reporting successful $operation"
    post_update_to_api "success" 0
}

# Usage
report_success "container installation"
report_success "package installation"
report_success "service configuration"
```

### Failure Reporting

```bash
#!/usr/bin/env bash
source api.func

# Report failed installation
report_failure() {
    local operation="$1"
    local exit_code="$2"

    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"

    local error_msg=$(get_error_description $exit_code)
    echo "Reporting failed $operation: $error_msg"
    post_update_to_api "failed" $exit_code
}

# Usage
report_failure "container creation" 200
report_failure "package installation" 127
report_failure "service start" 1
```

### Conditional Status Reporting

```bash
#!/usr/bin/env bash
source api.func

# Conditional status reporting
report_installation_status() {
    local operation="$1"
    local exit_code="$2"

    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"

    if [[ $exit_code -eq 0 ]]; then
        echo "Reporting successful $operation"
        post_update_to_api "success" 0
    else
        local error_msg=$(get_error_description $exit_code)
        echo "Reporting failed $operation: $error_msg"
        post_update_to_api "failed" $exit_code
    fi
}

# Usage
report_installation_status "container creation" 0
report_installation_status "package installation" 127
```

## Advanced Usage Examples

### Batch Installation with API Reporting

```bash
#!/usr/bin/env bash
source api.func

# Batch installation with comprehensive API reporting
batch_install_with_reporting() {
    local apps=("plex" "nextcloud" "nginx" "mysql")
    local ctids=(100 101 102 103)

    # Set up API reporting
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export CT_TYPE=1
    export DISK_SIZE=8
    export CORE_COUNT=2
    export RAM_SIZE=2048
    export var_os="debian"
    export var_version="12"
    export METHOD="install"

    local success_count=0
    local failure_count=0

    for i in "${!apps[@]}"; do
        local app="${apps[$i]}"
        local ctid="${ctids[$i]}"

        echo "Installing $app (ID: $ctid)..."

        # Set app-specific parameters
        export NSAPP="$app"

        # Report installation start
        post_to_api

        # Simulate installation
        if install_app "$app" "$ctid"; then
            echo "$app installed successfully"
            post_update_to_api "success" 0
            ((success_count++))
        else
            echo "$app installation failed"
            post_update_to_api "failed" $?
            ((failure_count++))
        fi

        echo "---"
    done

    echo "Batch installation completed: $success_count successful, $failure_count failed"
}

# Mock installation function
install_app() {
    local app="$1"
    local ctid="$2"

    # Simulate installation
    sleep 1

    # Simulate occasional failures
    if [[ $((RANDOM % 10)) -eq 0 ]]; then
        return 1
    fi

    return 0
}

batch_install_with_reporting
```

### Error Analysis and Reporting

```bash
#!/usr/bin/env bash
source api.func

# Analyze and report errors
analyze_and_report_errors() {
    local log_file="$1"

    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"

    if [[ ! -f "$log_file" ]]; then
        echo "Log file not found: $log_file"
        return 1
    fi

    # Extract error codes from log
    local error_codes=$(grep -o 'exit code [0-9]\+' "$log_file" | grep -o '[0-9]\+' | sort -u)

    if [[ -z "$error_codes" ]]; then
        echo "No errors found in log"
        post_update_to_api "success" 0
        return 0
    fi

    echo "Found error codes: $error_codes"

    # Report each unique error
    for code in $error_codes; do
        local error_msg=$(get_error_description $code)
        echo "Error $code: $error_msg"
        post_update_to_api "failed" $code
    done
}

# Usage
analyze_and_report_errors "/var/log/installation.log"
```

### API Health Check

```bash
#!/usr/bin/env bash
source api.func

# Check API connectivity and functionality
check_api_health() {
    echo "Checking API health..."

    # Test prerequisites
    if ! command -v curl >/dev/null 2>&1; then
        echo "ERROR: curl not available"
        return 1
    fi

    # Test error description function
    local test_error=$(get_error_description 127)
    if [[ -z "$test_error" ]]; then
        echo "ERROR: Error description function not working"
        return 1
    fi

    echo "Error description test: $test_error"

    # Test API connectivity (without sending data)
    local api_url="https://api.community-scripts.org/dev/upload"
    if curl -s --head "$api_url" >/dev/null 2>&1; then
        echo "API endpoint is reachable"
    else
        echo "WARNING: API endpoint not reachable"
    fi

    echo "API health check completed"
}

check_api_health
```

## Integration Examples

### With build.func

```bash
#!/usr/bin/env bash
# Integration with build.func

source core.func
source api.func
source build.func

# Set up API reporting
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# Container creation with API reporting
create_container_with_reporting() {
    local app="$1"
    local ctid="$2"

    # Set container parameters
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

    # Report installation start
    post_to_api

    # Create container using build.func
    if source build.func; then
        echo "Container $app created successfully"
        post_update_to_api "success" 0
        return 0
    else
        echo "Container $app creation failed"
        post_update_to_api "failed" $?
        return 1
    fi
}

# Create containers
create_container_with_reporting "plex" "100"
create_container_with_reporting "nextcloud" "101"
```

### With vm-core.func

```bash
#!/usr/bin/env bash
# Integration with vm-core.func

source core.func
source api.func
source vm-core.func

# Set up VM API reporting
mkdir -p /usr/local/community-scripts
echo "DIAGNOSTICS=yes" > /usr/local/community-scripts/diagnostics

export RANDOM_UUID="$(uuidgen)"

# VM creation with API reporting
create_vm_with_reporting() {
    local app="$1"
    local vmid="$2"

    # Set VM parameters
    export APP="$app"
    export VMID="$vmid"
    export var_hostname="${app}-vm"
    export var_os="ubuntu"
    export var_version="22.04"
    export var_cpu="4"
    export var_ram="4096"
    export var_disk="20"

    # Report VM installation start
    post_to_api_vm

    # Create VM using vm-core.func
    if source vm-core.func; then
        echo "VM $app created successfully"
        post_update_to_api "success" 0
        return 0
    else
        echo "VM $app creation failed"
        post_update_to_api "failed" $?
        return 1
    fi
}

# Create VMs
create_vm_with_reporting "nextcloud" "200"
create_vm_with_reporting "wordpress" "201"
```

### With error_handler.func

```bash
#!/usr/bin/env bash
# Integration with error_handler.func

source core.func
source error_handler.func
source api.func

# Enhanced error handling with API reporting
enhanced_error_handler() {
    local exit_code=${1:-$?}
    local command=${2:-${BASH_COMMAND:-unknown}}

    # Get error description from api.func
    local error_msg=$(get_error_description $exit_code)

    # Display error information
    echo "Error $exit_code: $error_msg"
    echo "Command: $command"

    # Report error to API
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    post_update_to_api "failed" $exit_code

    # Use standard error handler
    error_handler $exit_code $command
}

# Set up enhanced error handling
trap 'enhanced_error_handler' ERR

# Test enhanced error handling
nonexistent_command
```

## Best Practices Examples

### Comprehensive API Integration

```bash
#!/usr/bin/env bash
# Comprehensive API integration example

source core.func
source api.func

# Set up comprehensive API reporting
setup_api_reporting() {
    # Enable diagnostics
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"

    # Set common parameters
    export CT_TYPE=1
    export DISK_SIZE=8
    export CORE_COUNT=2
    export RAM_SIZE=2048
    export var_os="debian"
    export var_version="12"
    export METHOD="install"

    echo "API reporting configured"
}

# Installation with comprehensive reporting
install_with_comprehensive_reporting() {
    local app="$1"
    local ctid="$2"

    # Set up API reporting
    setup_api_reporting
    export NSAPP="$app"

    # Report installation start
    post_to_api

    # Installation process
    echo "Installing $app..."

    # Simulate installation steps
    local steps=("Downloading" "Installing" "Configuring" "Starting")
    for step in "${steps[@]}"; do
        echo "$step $app..."
        sleep 1
    done

    # Check installation result
    if [[ $? -eq 0 ]]; then
        echo "$app installation completed successfully"
        post_update_to_api "success" 0
        return 0
    else
        echo "$app installation failed"
        post_update_to_api "failed" $?
        return 1
    fi
}

# Install multiple applications
apps=("plex" "nextcloud" "nginx" "mysql")
ctids=(100 101 102 103)

for i in "${!apps[@]}"; do
    install_with_comprehensive_reporting "${apps[$i]}" "${ctids[$i]}"
    echo "---"
done
```

### Error Recovery with API Reporting

```bash
#!/usr/bin/env bash
source api.func

# Error recovery with API reporting
retry_with_api_reporting() {
    local operation="$1"
    local max_attempts=3
    local attempt=1

    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"

    while [[ $attempt -le $max_attempts ]]; do
        echo "Attempt $attempt of $max_attempts: $operation"

        if $operation; then
            echo "Operation succeeded on attempt $attempt"
            post_update_to_api "success" 0
            return 0
        else
            local exit_code=$?
            local error_msg=$(get_error_description $exit_code)
            echo "Attempt $attempt failed: $error_msg"

            post_update_to_api "failed" $exit_code

            ((attempt++))

            if [[ $attempt -le $max_attempts ]]; then
                echo "Retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done

    echo "Operation failed after $max_attempts attempts"
    return 1
}

# Usage
retry_with_api_reporting "apt-get update"
retry_with_api_reporting "apt-get install -y package"
```

### API Reporting with Logging

```bash
#!/usr/bin/env bash
source api.func

# API reporting with detailed logging
install_with_logging_and_api() {
    local app="$1"
    local log_file="/var/log/${app}_installation.log"

    # Set up API reporting
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export NSAPP="$app"

    # Start logging
    exec > >(tee -a "$log_file")
    exec 2>&1

    echo "Starting $app installation at $(date)"

    # Report installation start
    post_to_api

    # Installation process
    echo "Installing $app..."

    # Simulate installation
    if install_app "$app"; then
        echo "$app installation completed successfully at $(date)"
        post_update_to_api "success" 0
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "$app installation failed at $(date): $error_msg"
        post_update_to_api "failed" $exit_code
        return $exit_code
    fi
}

# Mock installation function
install_app() {
    local app="$1"
    echo "Installing $app..."
    sleep 2
    return 0
}

# Install with logging and API reporting
install_with_logging_and_api "plex"
```
