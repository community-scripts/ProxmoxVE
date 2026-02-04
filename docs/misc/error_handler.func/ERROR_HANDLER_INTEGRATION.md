# error_handler.func Integration Guide

## Overview

This document describes how `error_handler.func` integrates with other components in the Proxmox Community Scripts project, including dependencies, data flow, and API surface.

## Dependencies

### External Dependencies

#### Required Commands
- **None**: Pure Bash implementation

#### Optional Commands
- **None**: No external command dependencies

### Internal Dependencies

#### core.func
- **Purpose**: Provides color variables for error display
- **Usage**: Uses `RD`, `CL`, `YWB` color variables
- **Integration**: Called automatically when core.func is sourced
- **Data Flow**: Color variables → error display formatting

## Integration Points

### With core.func

#### Silent Execution Integration
```bash
# core.func silent() function uses error_handler.func
silent() {
    local cmd="$*"
    local caller_line="${BASH_LINENO[0]:-unknown}"

    # Execute command
    "$@" >>"$SILENT_LOGFILE" 2>&1
    local rc=$?

    if [[ $rc -ne 0 ]]; then
        # Load error_handler.func if needed
        if ! declare -f explain_exit_code >/dev/null 2>&1; then
            source error_handler.func
        fi

        # Get error explanation
        local explanation
        explanation="$(explain_exit_code "$rc")"

        # Display error with explanation
        printf "\e[?25h"
        echo -e "\n${RD}[ERROR]${CL} in line ${RD}${caller_line}${CL}: exit code ${RD}${rc}${CL} (${explanation})"
        echo -e "${RD}Command:${CL} ${YWB}${cmd}${CL}\n"

        exit "$rc"
    fi
}
```

#### Color Variable Usage
```bash
# error_handler.func uses color variables from core.func
error_handler() {
    # ... error handling logic ...

    # Use color variables for error display
    echo -e "\n${RD}[ERROR]${CL} in line ${RD}${line_number}${CL}: exit code ${RD}${exit_code}${CL} (${explanation}): while executing command ${YWB}${command}${CL}\n"
}

on_interrupt() {
    echo -e "\n${RD}Interrupted by user (SIGINT)${CL}"
    exit 130
}

on_terminate() {
    echo -e "\n${RD}Terminated by signal (SIGTERM)${CL}"
    exit 143
}
```

### With build.func

#### Container Creation Error Handling
```bash
# build.func uses error_handler.func for container operations
source core.func
source error_handler.func

# Container creation with error handling
create_container() {
    # Set up error handling
    catch_errors

    # Container creation operations
    silent pct create "$CTID" "$TEMPLATE" \
        --hostname "$HOSTNAME" \
        --memory "$MEMORY" \
        --cores "$CORES"

    # If creation fails, error_handler provides explanation
}
```

#### Template Download Error Handling
```bash
# build.func uses error_handler.func for template operations
download_template() {
    # Template download with error handling
    if ! silent curl -fsSL "$TEMPLATE_URL" -o "$TEMPLATE_FILE"; then
        # error_handler provides detailed explanation
        exit 222  # Template download failed
    fi
}
```

### With tools.func

#### Maintenance Operations Error Handling
```bash
# tools.func uses error_handler.func for maintenance operations
source core.func
source error_handler.func

# Maintenance operations with error handling
update_system() {
    catch_errors

    # System update operations
    silent apt-get update
    silent apt-get upgrade -y

    # Error handling provides explanations for failures
}

cleanup_logs() {
    catch_errors

    # Log cleanup operations
    silent find /var/log -name "*.log" -mtime +30 -delete

    # Error handling provides explanations for permission issues
}
```

### With api.func

#### API Operations Error Handling
```bash
# api.func uses error_handler.func for API operations
source core.func
source error_handler.func

# API operations with error handling
api_call() {
    catch_errors

    # API call with error handling
    if ! silent curl -k -H "Authorization: PVEAPIToken=$API_TOKEN" \
        "$API_URL/api2/json/nodes/$NODE/lxc"; then
        # error_handler provides explanation for API failures
        exit 1
    fi
}
```

### With install.func

#### Installation Process Error Handling
```bash
# install.func uses error_handler.func for installation operations
source core.func
source error_handler.func

# Installation with error handling
install_package() {
    local package="$1"

    catch_errors

    # Package installation
    silent apt-get install -y "$package"

    # Error handling provides explanations for installation failures
}
```

### With alpine-install.func

#### Alpine Installation Error Handling
```bash
# alpine-install.func uses error_handler.func for Alpine operations
source core.func
source error_handler.func

# Alpine installation with error handling
install_alpine_package() {
    local package="$1"

    catch_errors

    # Alpine package installation
    silent apk add --no-cache "$package"

    # Error handling provides explanations for Alpine-specific failures
}
```

### With alpine-tools.func

#### Alpine Tools Error Handling
```bash
# alpine-tools.func uses error_handler.func for Alpine tools
source core.func
source error_handler.func

# Alpine tools with error handling
alpine_tool_operation() {
    catch_errors

    # Alpine-specific tool operations
    silent alpine_command

    # Error handling provides explanations for Alpine tool failures
}
```

### With passthrough.func

#### Hardware Passthrough Error Handling
```bash
# passthrough.func uses error_handler.func for hardware operations
source core.func
source error_handler.func

# Hardware passthrough with error handling
configure_gpu_passthrough() {
    catch_errors

    # GPU passthrough operations
    silent lspci | grep -i nvidia

    # Error handling provides explanations for hardware failures
}
```

### With vm-core.func

#### VM Operations Error Handling
```bash
# vm-core.func uses error_handler.func for VM operations
source core.func
source error_handler.func

# VM operations with error handling
create_vm() {
    catch_errors

    # VM creation operations
    silent qm create "$VMID" \
        --name "$VMNAME" \
        --memory "$MEMORY" \
        --cores "$CORES"

    # Error handling provides explanations for VM creation failures
}
```

## Data Flow

### Input Data

#### Environment Variables
- **`DEBUG_LOGFILE`**: Path to debug log file for error logging
- **`SILENT_LOGFILE`**: Path to silent execution log file
- **`STRICT_UNSET`**: Enable strict unset variable checking (0/1)
- **`lockfile`**: Lock file path for cleanup (set by calling script)

#### Function Parameters
- **Exit codes**: Passed to `explain_exit_code()` and `error_handler()`
- **Command information**: Passed to `error_handler()` for context
- **Signal information**: Passed to signal handlers

#### System Information
- **Exit codes**: Retrieved from `$?` variable
- **Command information**: Retrieved from `BASH_COMMAND` variable
- **Line numbers**: Retrieved from `BASH_LINENO[0]` variable
- **Process information**: Retrieved from system calls

### Processing Data

#### Error Code Processing
- **Code classification**: Categorize exit codes by type
- **Explanation lookup**: Map codes to human-readable messages
- **Context collection**: Gather command and line information
- **Log preparation**: Format error information for logging

#### Signal Processing
- **Signal detection**: Identify received signals
- **Handler selection**: Choose appropriate signal handler
- **Cleanup operations**: Perform necessary cleanup
- **Exit code setting**: Set appropriate exit codes

#### Log Processing
- **Debug logging**: Write error information to debug log
- **Silent log integration**: Display silent log content
- **Log formatting**: Format log entries for readability
- **Log analysis**: Provide log analysis capabilities

### Output Data

#### Error Information
- **Error messages**: Human-readable error explanations
- **Context information**: Line numbers, commands, timestamps
- **Color formatting**: ANSI color codes for terminal display
- **Log content**: Silent log excerpts and debug information

#### System State
- **Exit codes**: Returned from functions
- **Log files**: Created and updated for error tracking
- **Cleanup status**: Lock file removal and process cleanup
- **Signal handling**: Graceful signal processing

## API Surface

### Public Functions

#### Error Explanation
- **`explain_exit_code()`**: Convert exit codes to explanations
- **Parameters**: Exit code to explain
- **Returns**: Human-readable explanation string
- **Usage**: Called by error_handler() and other functions

#### Error Handling
- **`error_handler()`**: Main error handler function
- **Parameters**: Exit code (optional), command (optional)
- **Returns**: None (exits with error code)
- **Usage**: Called by ERR trap or manually

#### Signal Handling
- **`on_interrupt()`**: Handle SIGINT signals
- **`on_terminate()`**: Handle SIGTERM signals
- **`on_exit()`**: Handle script exit cleanup
- **Parameters**: None
- **Returns**: None (exits with signal code)
- **Usage**: Called by signal traps

#### Initialization
- **`catch_errors()`**: Initialize error handling
- **Parameters**: None
- **Returns**: None
- **Usage**: Called to set up error handling traps

### Internal Functions

#### None
- All functions in error_handler.func are public
- No internal helper functions
- Direct implementation of all functionality

### Global Variables

#### Configuration Variables
- **`DEBUG_LOGFILE`**: Debug log file path
- **`SILENT_LOGFILE`**: Silent log file path
- **`STRICT_UNSET`**: Strict mode setting
- **`lockfile`**: Lock file path

#### State Variables
- **`exit_code`**: Current exit code
- **`command`**: Failed command
- **`line_number`**: Line number where error occurred
- **`explanation`**: Error explanation text

## Integration Patterns

### Standard Integration Pattern

```bash
#!/usr/bin/env bash
# Standard integration pattern

# 1. Source core.func first
source core.func

# 2. Source error_handler.func
source error_handler.func

# 3. Initialize error handling
catch_errors

# 4. Use silent execution
silent command

# 5. Errors are automatically handled
```

### Minimal Integration Pattern

```bash
#!/usr/bin/env bash
# Minimal integration pattern

source error_handler.func
catch_errors

# Basic error handling
command
```

### Advanced Integration Pattern

```bash
#!/usr/bin/env bash
# Advanced integration pattern

source core.func
source error_handler.func

# Set up comprehensive error handling
export DEBUG_LOGFILE="/tmp/debug.log"
export SILENT_LOGFILE="/tmp/silent.log"
lockfile="/tmp/script.lock"
touch "$lockfile"

catch_errors
trap on_interrupt INT
trap on_terminate TERM
trap on_exit EXIT

# Advanced error handling
silent command
```

## Error Handling Integration

### Automatic Error Handling
- **ERR Trap**: Automatically catches command failures
- **Error Explanation**: Provides human-readable error messages
- **Context Information**: Shows line numbers and commands
- **Log Integration**: Displays silent log content

### Manual Error Handling
- **Custom Error Codes**: Use Proxmox custom error codes
- **Error Recovery**: Implement retry logic with error handling
- **Conditional Handling**: Different handling for different error types
- **Error Analysis**: Analyze error patterns and trends

### Signal Handling Integration
- **Graceful Interruption**: Handle Ctrl+C gracefully
- **Clean Termination**: Handle SIGTERM signals
- **Exit Cleanup**: Clean up resources on script exit
- **Lock File Management**: Remove lock files on exit

## Performance Considerations

### Error Handling Overhead
- **Minimal Impact**: Error handling adds minimal overhead
- **Trap Setup**: Trap setup is done once during initialization
- **Error Processing**: Error processing is only done on failures
- **Log Writing**: Log writing is only done when enabled

### Memory Usage
- **Minimal Footprint**: Error handler uses minimal memory
- **Variable Reuse**: Global variables reused across functions
- **No Memory Leaks**: Proper cleanup prevents memory leaks
- **Efficient Processing**: Efficient error code processing

### Execution Speed
- **Fast Error Detection**: Quick error detection and handling
- **Efficient Explanation**: Fast error code explanation lookup
- **Minimal Delay**: Minimal delay in error handling
- **Quick Exit**: Fast exit on error conditions

## Security Considerations

### Error Information Disclosure
- **Controlled Disclosure**: Only necessary error information is shown
- **Log Security**: Log files have appropriate permissions
- **Sensitive Data**: Sensitive data is not logged
- **Error Sanitization**: Error messages are sanitized

### Signal Handling Security
- **Signal Validation**: Only expected signals are handled
- **Cleanup Security**: Secure cleanup of temporary files
- **Lock File Security**: Secure lock file management
- **Process Security**: Secure process termination

### Log File Security
- **File Permissions**: Log files have appropriate permissions
- **Log Rotation**: Log files are rotated to prevent disk filling
- **Log Cleanup**: Old log files are cleaned up
- **Log Access**: Log access is controlled

## Future Integration Considerations

### Extensibility
- **New Error Codes**: Easy to add new error code explanations
- **Custom Handlers**: Easy to add custom error handlers
- **Signal Extensions**: Easy to add new signal handlers
- **Log Formats**: Easy to add new log formats

### Compatibility
- **Bash Version**: Compatible with different Bash versions
- **System Compatibility**: Compatible with different systems
- **Script Compatibility**: Compatible with different script types
- **Error Code Compatibility**: Compatible with different error codes

### Performance
- **Optimization**: Error handling can be optimized for better performance
- **Caching**: Error explanations can be cached for faster lookup
- **Parallel Processing**: Error handling can be parallelized
- **Resource Management**: Better resource management for error handling
