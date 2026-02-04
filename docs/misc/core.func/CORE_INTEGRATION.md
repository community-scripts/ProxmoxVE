# core.func Integration Guide

## Overview

This document describes how `core.func` integrates with other components in the Proxmox Community Scripts project, including dependencies, data flow, and API surface.

## Dependencies

### External Dependencies

#### Required Commands
- **`pveversion`**: Proxmox VE version checking
- **`dpkg`**: Architecture detection
- **`ps`**: Process and shell detection
- **`id`**: User ID checking
- **`curl`**: Header file downloading
- **`swapon`**: Swap status checking
- **`dd`**: Swap file creation
- **`mkswap`**: Swap file formatting

#### Optional Commands
- **`tput`**: Terminal control (installed if missing)
- **`apk`**: Alpine package manager
- **`apt-get`**: Debian package manager

### Internal Dependencies

#### error_handler.func
- **Purpose**: Provides error code explanations for silent execution
- **Usage**: Automatically loaded when `silent()` encounters errors
- **Integration**: Called via `explain_exit_code()` function
- **Data Flow**: Error code → explanation → user display

## Integration Points

### With build.func

#### System Validation
```bash
# build.func uses core.func for system checks
source core.func
pve_check
arch_check
shell_check
root_check
```

#### User Interface
```bash
# build.func uses core.func for UI elements
msg_info "Creating container..."
msg_ok "Container created successfully"
msg_error "Container creation failed"
```

#### Silent Execution
```bash
# build.func uses core.func for command execution
silent pct create "$CTID" "$TEMPLATE" \
    --hostname "$HOSTNAME" \
    --memory "$MEMORY" \
    --cores "$CORES"
```

### With tools.func

#### Utility Functions
```bash
# tools.func uses core.func utilities
source core.func

# System checks
pve_check
root_check

# UI elements
msg_info "Running maintenance tasks..."
msg_ok "Maintenance completed"
```

#### Error Handling
```bash
# tools.func uses core.func for error handling
if silent systemctl restart service; then
    msg_ok "Service restarted"
else
    msg_error "Service restart failed"
fi
```

### With api.func

#### System Validation
```bash
# api.func uses core.func for system checks
source core.func
pve_check
root_check
```

#### API Operations
```bash
# api.func uses core.func for API calls
msg_info "Connecting to Proxmox API..."
if silent curl -k -H "Authorization: PVEAPIToken=$API_TOKEN" \
    "$API_URL/api2/json/nodes/$NODE/lxc"; then
    msg_ok "API connection successful"
else
    msg_error "API connection failed"
fi
```

### With error_handler.func

#### Error Explanations
```bash
# error_handler.func provides explanations for core.func
explain_exit_code() {
    local code="$1"
    case "$code" in
        1) echo "General error" ;;
        2) echo "Misuse of shell builtins" ;;
        126) echo "Command invoked cannot execute" ;;
        127) echo "Command not found" ;;
        128) echo "Invalid argument to exit" ;;
        *) echo "Unknown error code" ;;
    esac
}
```

### With install.func

#### Installation Process
```bash
# install.func uses core.func for installation
source core.func

# System checks
pve_check
root_check

# Installation steps
msg_info "Installing packages..."
silent apt-get update
silent apt-get install -y package

msg_ok "Installation completed"
```

### With alpine-install.func

#### Alpine-Specific Operations
```bash
# alpine-install.func uses core.func for Alpine operations
source core.func

# Alpine detection
if is_alpine; then
    msg_info "Detected Alpine Linux"
    silent apk add --no-cache package
else
    msg_info "Detected Debian-based system"
    silent apt-get install -y package
fi
```

### With alpine-tools.func

#### Alpine Utilities
```bash
# alpine-tools.func uses core.func for Alpine tools
source core.func

# Alpine-specific operations
if is_alpine; then
    msg_info "Running Alpine-specific operations..."
    # Alpine tools logic
    msg_ok "Alpine operations completed"
fi
```

### With passthrough.func

#### Hardware Passthrough
```bash
# passthrough.func uses core.func for hardware operations
source core.func

# System checks
pve_check
root_check

# Hardware operations
msg_info "Configuring GPU passthrough..."
if silent lspci | grep -i nvidia; then
    msg_ok "NVIDIA GPU detected"
else
    msg_warn "No NVIDIA GPU found"
fi
```

### With vm-core.func

#### VM Operations
```bash
# vm-core.func uses core.func for VM management
source core.func

# System checks
pve_check
root_check

# VM operations
msg_info "Creating virtual machine..."
silent qm create "$VMID" \
    --name "$VMNAME" \
    --memory "$MEMORY" \
    --cores "$CORES"

msg_ok "Virtual machine created"
```

## Data Flow

### Input Data

#### Environment Variables
- **`APP`**: Application name for header display
- **`APP_TYPE`**: Application type (ct/vm) for header paths
- **`VERBOSE`**: Verbose mode setting
- **`var_os`**: OS type for Alpine detection
- **`PCT_OSTYPE`**: Alternative OS type variable
- **`var_verbose`**: Alternative verbose setting
- **`var_full_verbose`**: Debug mode setting

#### Command Parameters
- **Function arguments**: Passed to individual functions
- **Command arguments**: Passed to `silent()` function
- **User input**: Collected via `read` commands

### Processing Data

#### System Information
- **Proxmox version**: Parsed from `pveversion` output
- **Architecture**: Retrieved from `dpkg --print-architecture`
- **Shell type**: Detected from process information
- **User ID**: Retrieved from `id -u`
- **SSH connection**: Detected from `SSH_CLIENT` environment

#### UI State
- **Message tracking**: `MSG_INFO_SHOWN` associative array
- **Spinner state**: `SPINNER_PID` and `SPINNER_MSG` variables
- **Terminal state**: Cursor position and display mode

#### Error Information
- **Exit codes**: Captured from command execution
- **Log output**: Redirected to temporary log files
- **Error explanations**: Retrieved from error_handler.func

### Output Data

#### User Interface
- **Colored messages**: ANSI color codes for terminal output
- **Icons**: Symbolic representations for different message types
- **Spinners**: Animated progress indicators
- **Formatted text**: Consistent message formatting

#### System State
- **Exit codes**: Returned from functions
- **Log files**: Created for silent execution
- **Configuration**: Modified system settings
- **Process state**: Spinner processes and cleanup

## API Surface

### Public Functions

#### System Validation
- **`pve_check()`**: Proxmox VE version validation
- **`arch_check()`**: Architecture validation
- **`shell_check()`**: Shell validation
- **`root_check()`**: Privilege validation
- **`ssh_check()`**: SSH connection warning

#### User Interface
- **`msg_info()`**: Informational messages
- **`msg_ok()`**: Success messages
- **`msg_error()`**: Error messages
- **`msg_warn()`**: Warning messages
- **`msg_custom()`**: Custom messages
- **`msg_debug()`**: Debug messages

#### Spinner Control
- **`spinner()`**: Start spinner animation
- **`stop_spinner()`**: Stop spinner and cleanup
- **`clear_line()`**: Clear current terminal line

#### Silent Execution
- **`silent()`**: Execute commands with error handling

#### Utility Functions
- **`is_alpine()`**: Alpine Linux detection
- **`is_verbose_mode()`**: Verbose mode detection
- **`fatal()`**: Fatal error handling
- **`ensure_tput()`**: Terminal control setup

#### Header Management
- **`get_header()`**: Download application headers
- **`header_info()`**: Display header information

#### System Management
- **`check_or_create_swap()`**: Swap file management

### Internal Functions

#### Initialization
- **`load_functions()`**: Function loader
- **`color()`**: Color setup
- **`formatting()`**: Formatting setup
- **`icons()`**: Icon setup
- **`default_vars()`**: Default variables
- **`set_std_mode()`**: Standard mode setup

#### Color Management
- **`color_spinner()`**: Spinner colors

### Global Variables

#### Color Variables
- **`YW`**, **`YWB`**, **`BL`**, **`RD`**, **`BGN`**, **`GN`**, **`DGN`**, **`CL`**: Color codes
- **`CS_YW`**, **`CS_YWB`**, **`CS_CL`**: Spinner colors

#### Formatting Variables
- **`BFR`**, **`BOLD`**, **`HOLD`**, **`TAB`**, **`TAB3`**: Formatting helpers

#### Icon Variables
- **`CM`**, **`CROSS`**, **`INFO`**, **`OS`**, **`OSVERSION`**, etc.: Message icons

#### Configuration Variables
- **`RETRY_NUM`**, **`RETRY_EVERY`**: Retry settings
- **`STD`**: Standard mode setting
- **`SILENT_LOGFILE`**: Log file path

#### State Variables
- **`_CORE_FUNC_LOADED`**: Loading prevention
- **`__FUNCTIONS_LOADED`**: Function loading prevention
- **`SPINNER_PID`**, **`SPINNER_MSG`**: Spinner state
- **`MSG_INFO_SHOWN`**: Message tracking

## Integration Patterns

### Standard Integration Pattern

```bash
#!/usr/bin/env bash
# Standard integration pattern

# 1. Source core.func first
source core.func

# 2. Run system checks
pve_check
arch_check
shell_check
root_check

# 3. Set up error handling
trap 'stop_spinner' EXIT INT TERM

# 4. Use UI functions
msg_info "Starting operation..."

# 5. Use silent execution
silent command

# 6. Show completion
msg_ok "Operation completed"
```

### Minimal Integration Pattern

```bash
#!/usr/bin/env bash
# Minimal integration pattern

source core.func
pve_check
root_check

msg_info "Running operation..."
silent command
msg_ok "Operation completed"
```

### Advanced Integration Pattern

```bash
#!/usr/bin/env bash
# Advanced integration pattern

source core.func

# System validation
pve_check
arch_check
shell_check
root_check
ssh_check

# Error handling
trap 'stop_spinner' EXIT INT TERM

# Verbose mode handling
if is_verbose_mode; then
    msg_info "Verbose mode enabled"
fi

# OS-specific operations
if is_alpine; then
    msg_info "Alpine Linux detected"
    # Alpine-specific logic
else
    msg_info "Debian-based system detected"
    # Debian-specific logic
fi

# Operation execution
msg_info "Starting operation..."
if silent command; then
    msg_ok "Operation succeeded"
else
    msg_error "Operation failed"
    exit 1
fi
```

## Error Handling Integration

### Silent Execution Error Flow

```
silent() command
├── Execute command
├── Capture output to log
├── Check exit code
├── If error:
│   ├── Load error_handler.func
│   ├── Get error explanation
│   ├── Display error details
│   ├── Show log excerpt
│   └── Exit with error code
└── If success: Continue
```

### System Check Error Flow

```
System Check Function
├── Check system state
├── If valid: Return 0
└── If invalid:
    ├── Display error message
    ├── Show fix instructions
    ├── Sleep for user to read
    └── Exit with error code
```

## Performance Considerations

### Loading Optimization
- **Single Loading**: `_CORE_FUNC_LOADED` prevents multiple loading
- **Function Loading**: `__FUNCTIONS_LOADED` prevents multiple function loading
- **Lazy Loading**: Functions loaded only when needed

### Memory Usage
- **Minimal Footprint**: Core functions use minimal memory
- **Variable Reuse**: Global variables reused across functions
- **Cleanup**: Spinner processes cleaned up on exit

### Execution Speed
- **Fast Checks**: System checks are optimized for speed
- **Efficient Spinners**: Spinner animation uses minimal CPU
- **Quick Messages**: Message functions optimized for performance

## Security Considerations

### Privilege Escalation
- **Root Check**: Ensures script runs with sufficient privileges
- **Shell Check**: Validates shell environment
- **Process Validation**: Checks parent process for sudo usage

### Input Validation
- **Parameter Checking**: Functions validate input parameters
- **Error Handling**: Proper error handling prevents crashes
- **Safe Execution**: Silent execution with proper error handling

### System Protection
- **Version Validation**: Ensures compatible Proxmox version
- **Architecture Check**: Prevents execution on unsupported systems
- **SSH Warning**: Warns about external SSH usage

## Future Integration Considerations

### Extensibility
- **Function Groups**: Easy to add new function groups
- **Message Types**: Easy to add new message types
- **System Checks**: Easy to add new system checks

### Compatibility
- **Version Support**: Easy to add new Proxmox versions
- **OS Support**: Easy to add new operating systems
- **Architecture Support**: Easy to add new architectures

### Performance
- **Optimization**: Functions can be optimized for better performance
- **Caching**: Results can be cached for repeated operations
- **Parallelization**: Operations can be parallelized where appropriate
