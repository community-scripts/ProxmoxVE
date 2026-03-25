# api.func Integration Guide

## Overview

This document describes how `api.func` integrates with other components in the Proxmox Community Scripts project, including dependencies, data flow, and API surface.

## Dependencies

### External Dependencies

#### Required Commands
- **`curl`**: HTTP client for API communication
- **`uuidgen`**: Generate unique identifiers (optional, can use other methods)

#### Optional Commands
- **None**: No other external command dependencies

### Internal Dependencies

#### Environment Variables from Other Scripts
- **build.func**: Provides container creation variables
- **vm-core.func**: Provides VM creation variables
- **core.func**: Provides system information variables
- **Installation scripts**: Provide application-specific variables

## Integration Points

### With build.func

#### LXC Container Reporting
```bash
# build.func uses api.func for container reporting
source core.func
source api.func
source build.func

# Set up API reporting
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# Container creation with API reporting
create_container() {
    # Set container parameters
    export CT_TYPE=1
    export DISK_SIZE="$var_disk"
    export CORE_COUNT="$var_cpu"
    export RAM_SIZE="$var_ram"
    export var_os="$var_os"
    export var_version="$var_version"
    export NSAPP="$APP"
    export METHOD="install"

    # Report installation start
    post_to_api

    # Container creation using build.func
    # ... build.func container creation logic ...

    # Report completion
    if [[ $? -eq 0 ]]; then
        post_update_to_api "success" 0
    else
        post_update_to_api "failed" $?
    fi
}
```

#### Error Reporting Integration
```bash
# build.func uses api.func for error reporting
handle_container_error() {
    local exit_code=$1
    local error_msg=$(get_error_description $exit_code)

    echo "Container creation failed: $error_msg"
    post_update_to_api "failed" $exit_code
}
```

### With vm-core.func

#### VM Installation Reporting
```bash
# vm-core.func uses api.func for VM reporting
source core.func
source api.func
source vm-core.func

# Set up VM API reporting
mkdir -p /usr/local/community-scripts
echo "DIAGNOSTICS=yes" > /usr/local/community-scripts/diagnostics

export RANDOM_UUID="$(uuidgen)"

# VM creation with API reporting
create_vm() {
    # Set VM parameters
    export DISK_SIZE="${var_disk}G"
    export CORE_COUNT="$var_cpu"
    export RAM_SIZE="$var_ram"
    export var_os="$var_os"
    export var_version="$var_version"
    export NSAPP="$APP"
    export METHOD="install"

    # Report VM installation start
    post_to_api_vm

    # VM creation using vm-core.func
    # ... vm-core.func VM creation logic ...

    # Report completion
    post_update_to_api "success" 0
}
```

### With core.func

#### System Information Integration
```bash
# core.func provides system information for api.func
source core.func
source api.func

# Get system information for API reporting
get_system_info_for_api() {
    # Get PVE version using core.func utilities
    local pve_version=$(pveversion | awk -F'[/ ]' '{print $2}')

    # Set API parameters
    export var_os="$var_os"
    export var_version="$var_version"

    # Use core.func error handling with api.func reporting
    if silent apt-get update; then
        post_update_to_api "success" 0
    else
        post_update_to_api "failed" $?
    fi
}
```

### With error_handler.func

#### Error Description Integration
```bash
# error_handler.func uses api.func for error descriptions
source core.func
source error_handler.func
source api.func

# Enhanced error handler with API reporting
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
```

### With install.func

#### Installation Process Reporting
```bash
# install.func uses api.func for installation reporting
source core.func
source api.func
source install.func

# Installation with API reporting
install_package_with_reporting() {
    local package="$1"

    # Set up API reporting
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export NSAPP="$package"
    export METHOD="install"

    # Report installation start
    post_to_api

    # Package installation using install.func
    if install_package "$package"; then
        echo "$package installed successfully"
        post_update_to_api "success" 0
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "$package installation failed: $error_msg"
        post_update_to_api "failed" $exit_code
        return $exit_code
    fi
}
```

### With alpine-install.func

#### Alpine Installation Reporting
```bash
# alpine-install.func uses api.func for Alpine reporting
source core.func
source api.func
source alpine-install.func

# Alpine installation with API reporting
install_alpine_with_reporting() {
    local app="$1"

    # Set up API reporting
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export NSAPP="$app"
    export METHOD="install"
    export var_os="alpine"

    # Report Alpine installation start
    post_to_api

    # Alpine installation using alpine-install.func
    if install_alpine_app "$app"; then
        echo "Alpine $app installed successfully"
        post_update_to_api "success" 0
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "Alpine $app installation failed: $error_msg"
        post_update_to_api "failed" $exit_code
        return $exit_code
    fi
}
```

### With alpine-tools.func

#### Alpine Tools Reporting
```bash
# alpine-tools.func uses api.func for Alpine tools reporting
source core.func
source api.func
source alpine-tools.func

# Alpine tools with API reporting
run_alpine_tool_with_reporting() {
    local tool="$1"

    # Set up API reporting
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export NSAPP="alpine-tools"
    export METHOD="tool"

    # Report tool execution start
    post_to_api

    # Run Alpine tool using alpine-tools.func
    if run_alpine_tool "$tool"; then
        echo "Alpine tool $tool executed successfully"
        post_update_to_api "success" 0
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "Alpine tool $tool failed: $error_msg"
        post_update_to_api "failed" $exit_code
        return $exit_code
    fi
}
```

### With passthrough.func

#### Hardware Passthrough Reporting
```bash
# passthrough.func uses api.func for hardware reporting
source core.func
source api.func
source passthrough.func

# Hardware passthrough with API reporting
configure_passthrough_with_reporting() {
    local hardware_type="$1"

    # Set up API reporting
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export NSAPP="passthrough"
    export METHOD="hardware"

    # Report passthrough configuration start
    post_to_api

    # Configure passthrough using passthrough.func
    if configure_passthrough "$hardware_type"; then
        echo "Hardware passthrough configured successfully"
        post_update_to_api "success" 0
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "Hardware passthrough failed: $error_msg"
        post_update_to_api "failed" $exit_code
        return $exit_code
    fi
}
```

### With tools.func

#### Maintenance Operations Reporting
```bash
# tools.func uses api.func for maintenance reporting
source core.func
source api.func
source tools.func

# Maintenance operations with API reporting
run_maintenance_with_reporting() {
    local operation="$1"

    # Set up API reporting
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export NSAPP="maintenance"
    export METHOD="tool"

    # Report maintenance start
    post_to_api

    # Run maintenance using tools.func
    if run_maintenance_operation "$operation"; then
        echo "Maintenance operation $operation completed successfully"
        post_update_to_api "success" 0
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "Maintenance operation $operation failed: $error_msg"
        post_update_to_api "failed" $exit_code
        return $exit_code
    fi
}
```

## Data Flow

### Input Data

#### Environment Variables from Other Scripts
- **`CT_TYPE`**: Container type (1 for LXC, 2 for VM)
- **`DISK_SIZE`**: Disk size in GB
- **`CORE_COUNT`**: Number of CPU cores
- **`RAM_SIZE`**: RAM size in MB
- **`var_os`**: Operating system type
- **`var_version`**: OS version
- **`DISABLEIP6`**: IPv6 disable setting
- **`NSAPP`**: Namespace application name
- **`METHOD`**: Installation method
- **`DIAGNOSTICS`**: Enable/disable diagnostic reporting
- **`RANDOM_UUID`**: Unique identifier for tracking

#### Function Parameters
- **Exit codes**: Passed to `get_error_description()` and `post_update_to_api()`
- **Status information**: Passed to `post_update_to_api()`
- **API endpoints**: Hardcoded in functions

#### System Information
- **PVE version**: Retrieved from `pveversion` command
- **Disk size processing**: Processed for VM API (removes 'G' suffix)
- **Error codes**: Retrieved from command exit codes

### Processing Data

#### API Request Preparation
- **JSON payload creation**: Format data for API consumption
- **Data validation**: Ensure required fields are present
- **Error handling**: Handle missing or invalid data
- **Content type setting**: Set appropriate HTTP headers

#### Error Processing
- **Error code mapping**: Map numeric codes to descriptions
- **Error message formatting**: Format error descriptions
- **Unknown error handling**: Handle unrecognized error codes
- **Fallback messages**: Provide default error messages

#### API Communication
- **HTTP request preparation**: Prepare curl commands
- **Response handling**: Capture HTTP response codes
- **Error handling**: Handle network and API errors
- **Duplicate prevention**: Prevent duplicate status updates

### Output Data

#### API Communication
- **HTTP requests**: Sent to community-scripts.org API
- **Response codes**: Captured from API responses
- **Error information**: Reported to API
- **Status updates**: Sent to API

#### Error Information
- **Error descriptions**: Human-readable error messages
- **Error codes**: Mapped to descriptions
- **Context information**: Error context and details
- **Fallback messages**: Default error messages

#### System State
- **POST_UPDATE_DONE**: Prevents duplicate updates
- **RESPONSE**: Stores API response
- **JSON_PAYLOAD**: Stores formatted API data
- **API_URL**: Stores API endpoint

## API Surface

### Public Functions

#### Error Description
- **`get_error_description()`**: Convert exit codes to explanations
- **Parameters**: Exit code to explain
- **Returns**: Human-readable explanation string
- **Usage**: Called by other functions and scripts

#### API Communication
- **`post_to_api()`**: Send LXC installation data
- **`post_to_api_vm()`**: Send VM installation data
- **`post_update_to_api()`**: Send status updates
- **Parameters**: Status and exit code (for updates)
- **Returns**: None
- **Usage**: Called by installation scripts

### Internal Functions

#### None
- All functions in api.func are public
- No internal helper functions
- Direct implementation of all functionality

### Global Variables

#### Configuration Variables
- **`DIAGNOSTICS`**: Diagnostic reporting setting
- **`RANDOM_UUID`**: Unique tracking identifier
- **`POST_UPDATE_DONE`**: Duplicate update prevention

#### Data Variables
- **`CT_TYPE`**: Container type
- **`DISK_SIZE`**: Disk size
- **`CORE_COUNT`**: CPU core count
- **`RAM_SIZE`**: RAM size
- **`var_os`**: Operating system
- **`var_version`**: OS version
- **`DISABLEIP6`**: IPv6 setting
- **`NSAPP`**: Application namespace
- **`METHOD`**: Installation method

#### Internal Variables
- **`API_URL`**: API endpoint URL
- **`JSON_PAYLOAD`**: API request payload
- **`RESPONSE`**: API response
- **`DISK_SIZE_API`**: Processed disk size for VM API

## Integration Patterns

### Standard Integration Pattern

```bash
#!/usr/bin/env bash
# Standard integration pattern

# 1. Source core.func first
source core.func

# 2. Source api.func
source api.func

# 3. Set up API reporting
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# 4. Set application parameters
export NSAPP="$APP"
export METHOD="install"

# 5. Report installation start
post_to_api

# 6. Perform installation
# ... installation logic ...

# 7. Report completion
post_update_to_api "success" 0
```

### Minimal Integration Pattern

```bash
#!/usr/bin/env bash
# Minimal integration pattern

source api.func

# Basic error reporting
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# Report failure
post_update_to_api "failed" 127
```

### Advanced Integration Pattern

```bash
#!/usr/bin/env bash
# Advanced integration pattern

source core.func
source api.func
source error_handler.func

# Set up comprehensive API reporting
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"
export CT_TYPE=1
export DISK_SIZE=8
export CORE_COUNT=2
export RAM_SIZE=2048
export var_os="debian"
export var_version="12"
export METHOD="install"

# Enhanced error handling with API reporting
enhanced_error_handler() {
    local exit_code=${1:-$?}
    local command=${2:-${BASH_COMMAND:-unknown}}

    local error_msg=$(get_error_description $exit_code)
    echo "Error $exit_code: $error_msg"

    post_update_to_api "failed" $exit_code
    error_handler $exit_code $command
}

trap 'enhanced_error_handler' ERR

# Advanced operations with API reporting
post_to_api
# ... operations ...
post_update_to_api "success" 0
```

## Error Handling Integration

### Automatic Error Reporting
- **Error Descriptions**: Provides human-readable error messages
- **API Integration**: Reports errors to community-scripts.org API
- **Error Tracking**: Tracks error patterns for project improvement
- **Diagnostic Data**: Contributes to anonymous usage analytics

### Manual Error Reporting
- **Custom Error Codes**: Use appropriate error codes for different scenarios
- **Error Context**: Provide context information for errors
- **Status Updates**: Report both success and failure cases
- **Error Analysis**: Analyze error patterns and trends

### API Communication Errors
- **Network Failures**: Handle API communication failures gracefully
- **Missing Prerequisites**: Check prerequisites before API calls
- **Duplicate Prevention**: Prevent duplicate status updates
- **Error Recovery**: Handle API errors without blocking installation

## Performance Considerations

### API Communication Overhead
- **Minimal Impact**: API calls add minimal overhead
- **Asynchronous**: API calls don't block installation process
- **Error Handling**: API failures don't affect installation
- **Optional**: API reporting is optional and can be disabled

### Memory Usage
- **Minimal Footprint**: API functions use minimal memory
- **Variable Reuse**: Global variables reused across functions
- **No Memory Leaks**: Proper cleanup prevents memory leaks
- **Efficient Processing**: Efficient JSON payload creation

### Execution Speed
- **Fast API Calls**: Quick API communication
- **Efficient Error Processing**: Fast error code processing
- **Minimal Delay**: Minimal delay in API operations
- **Non-blocking**: API calls don't block installation

## Security Considerations

### Data Privacy
- **Anonymous Reporting**: Only anonymous data is sent
- **No Sensitive Data**: No sensitive information is transmitted
- **User Control**: Users can disable diagnostic reporting
- **Data Minimization**: Only necessary data is sent

### API Security
- **HTTPS**: API communication uses secure protocols
- **Data Validation**: API data is validated before sending
- **Error Handling**: API errors are handled securely
- **No Credentials**: No authentication credentials are sent

### Network Security
- **Secure Communication**: Uses secure HTTP protocols
- **Error Handling**: Network errors are handled gracefully
- **No Data Leakage**: No sensitive data is leaked
- **Secure Endpoints**: Uses trusted API endpoints

## Future Integration Considerations

### Extensibility
- **New API Endpoints**: Easy to add new API endpoints
- **Additional Data**: Easy to add new data fields
- **Error Codes**: Easy to add new error code descriptions
- **API Versions**: Easy to support new API versions

### Compatibility
- **API Versioning**: Compatible with different API versions
- **Data Format**: Compatible with different data formats
- **Error Codes**: Compatible with different error code systems
- **Network Protocols**: Compatible with different network protocols

### Performance
- **Optimization**: API communication can be optimized
- **Caching**: API responses can be cached
- **Batch Operations**: Multiple operations can be batched
- **Async Processing**: API calls can be made asynchronous
