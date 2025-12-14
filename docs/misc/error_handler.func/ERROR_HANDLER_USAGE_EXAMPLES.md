# error_handler.func Usage Examples

## Overview

This document provides practical usage examples for `error_handler.func` functions, covering common scenarios, integration patterns, and best practices.

## Basic Error Handling Setup

### Standard Script Initialization

```bash
#!/usr/bin/env bash
# Standard error handling setup

# Source error handler
source error_handler.func

# Initialize error handling
catch_errors

# Your script code here
# All errors will be automatically caught and handled
echo "Script running..."
apt-get update
apt-get install -y package
echo "Script completed successfully"
```

### Minimal Error Handling

```bash
#!/usr/bin/env bash
# Minimal error handling setup

source error_handler.func
catch_errors

# Simple script with error handling
echo "Starting operation..."
command_that_might_fail
echo "Operation completed"
```

## Error Code Explanation Examples

### Basic Error Explanation

```bash
#!/usr/bin/env bash
source error_handler.func

# Explain common error codes
echo "Error 1: $(explain_exit_code 1)"
echo "Error 127: $(explain_exit_code 127)"
echo "Error 130: $(explain_exit_code 130)"
echo "Error 200: $(explain_exit_code 200)"
```

### Error Code Testing

```bash
#!/usr/bin/env bash
source error_handler.func

# Test all error codes
test_error_codes() {
    local codes=(1 2 126 127 128 130 137 139 143 100 101 255 200 203 204 205)

    for code in "${codes[@]}"; do
        echo "Code $code: $(explain_exit_code $code)"
    done
}

test_error_codes
```

### Custom Error Code Usage

```bash
#!/usr/bin/env bash
source error_handler.func

# Use custom error codes
check_requirements() {
    if [[ ! -f /required/file ]]; then
        echo "Error: Required file missing"
        exit 200  # Custom error code
    fi

    if [[ -z "$CTID" ]]; then
        echo "Error: CTID not set"
        exit 203  # Custom error code
    fi

    if [[ $CTID -lt 100 ]]; then
        echo "Error: Invalid CTID"
        exit 205  # Custom error code
    fi
}

check_requirements
```

## Signal Handling Examples

### Interrupt Handling

```bash
#!/usr/bin/env bash
source error_handler.func

# Set up interrupt handler
trap on_interrupt INT

echo "Script running... Press Ctrl+C to interrupt"
sleep 10
echo "Script completed normally"
```

### Termination Handling

```bash
#!/usr/bin/env bash
source error_handler.func

# Set up termination handler
trap on_terminate TERM

echo "Script running... Send SIGTERM to terminate"
sleep 10
echo "Script completed normally"
```

### Complete Signal Handling

```bash
#!/usr/bin/env bash
source error_handler.func

# Set up all signal handlers
trap on_interrupt INT
trap on_terminate TERM
trap on_exit EXIT

echo "Script running with full signal handling"
sleep 10
echo "Script completed normally"
```

## Cleanup Examples

### Lock File Cleanup

```bash
#!/usr/bin/env bash
source error_handler.func

# Set up lock file
lockfile="/tmp/my_script.lock"
touch "$lockfile"

# Set up exit handler
trap on_exit EXIT

echo "Script running with lock file..."
sleep 5
echo "Script completed - lock file will be removed"
```

### Temporary File Cleanup

```bash
#!/usr/bin/env bash
source error_handler.func

# Create temporary files
temp_file1="/tmp/temp1.$$"
temp_file2="/tmp/temp2.$$"
touch "$temp_file1" "$temp_file2"

# Set up cleanup
cleanup() {
    rm -f "$temp_file1" "$temp_file2"
    echo "Temporary files cleaned up"
}

trap cleanup EXIT

echo "Script running with temporary files..."
sleep 5
echo "Script completed - temporary files will be cleaned up"
```

## Debug Logging Examples

### Basic Debug Logging

```bash
#!/usr/bin/env bash
source error_handler.func

# Enable debug logging
export DEBUG_LOGFILE="/tmp/debug.log"
catch_errors

echo "Script with debug logging"
apt-get update
apt-get install -y package
```

### Debug Log Analysis

```bash
#!/usr/bin/env bash
source error_handler.func

# Enable debug logging
export DEBUG_LOGFILE="/tmp/debug.log"
catch_errors

# Function to analyze debug log
analyze_debug_log() {
    if [[ -f "$DEBUG_LOGFILE" ]]; then
        echo "Debug log analysis:"
        echo "Total errors: $(grep -c "ERROR" "$DEBUG_LOGFILE")"
        echo "Recent errors:"
        tail -n 5 "$DEBUG_LOGFILE"
    else
        echo "No debug log found"
    fi
}

# Run script
echo "Running script..."
apt-get update

# Analyze results
analyze_debug_log
```

## Silent Execution Integration

### With core.func Silent Execution

```bash
#!/usr/bin/env bash
source core.func
source error_handler.func

# Silent execution with error handling
echo "Installing packages..."
silent apt-get update
silent apt-get install -y nginx

echo "Configuring service..."
silent systemctl enable nginx
silent systemctl start nginx

echo "Installation completed"
```

### Silent Execution Error Handling

```bash
#!/usr/bin/env bash
source core.func
source error_handler.func

# Function with silent execution and error handling
install_package() {
    local package="$1"

    echo "Installing $package..."
    if silent apt-get install -y "$package"; then
        echo "$package installed successfully"
        return 0
    else
        echo "Failed to install $package"
        return 1
    fi
}

# Install multiple packages
packages=("nginx" "apache2" "mysql-server")
for package in "${packages[@]}"; do
    if ! install_package "$package"; then
        echo "Stopping installation due to error"
        exit 1
    fi
done
```

## Advanced Error Handling Examples

### Conditional Error Handling

```bash
#!/usr/bin/env bash
source error_handler.func

# Conditional error handling based on environment
setup_error_handling() {
    if [[ "${STRICT_MODE:-0}" == "1" ]]; then
        echo "Enabling strict mode"
        export STRICT_UNSET=1
    fi

    catch_errors
    echo "Error handling configured"
}

setup_error_handling
```

### Error Recovery

```bash
#!/usr/bin/env bash
source error_handler.func

# Error recovery pattern
retry_operation() {
    local max_attempts=3
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        echo "Attempt $attempt of $max_attempts"

        if silent "$@"; then
            echo "Operation succeeded on attempt $attempt"
            return 0
        else
            echo "Attempt $attempt failed"
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

# Use retry pattern
retry_operation apt-get update
retry_operation apt-get install -y package
```

### Custom Error Handler

```bash
#!/usr/bin/env bash
source error_handler.func

# Custom error handler for specific operations
custom_error_handler() {
    local exit_code=${1:-$?}
    local command=${2:-${BASH_COMMAND:-unknown}}

    case "$exit_code" in
        127)
            echo "Custom handling: Command not found - $command"
            echo "Suggestions:"
            echo "1. Check if the command is installed"
            echo "2. Check if the command is in PATH"
            echo "3. Check spelling"
            ;;
        126)
            echo "Custom handling: Permission denied - $command"
            echo "Suggestions:"
            echo "1. Check file permissions"
            echo "2. Run with appropriate privileges"
            echo "3. Check if file is executable"
            ;;
        *)
            # Use default error handler
            error_handler "$exit_code" "$command"
            ;;
    esac
}

# Set up custom error handler
trap 'custom_error_handler' ERR

# Test custom error handling
nonexistent_command
```

## Integration Examples

### With build.func

```bash
#!/usr/bin/env bash
# Integration with build.func

source core.func
source error_handler.func
source build.func

# Container creation with error handling
export APP="plex"
export CTID="100"

# Errors will be caught and explained
# Silent execution will use error_handler for explanations
```

### With tools.func

```bash
#!/usr/bin/env bash
# Integration with tools.func

source core.func
source error_handler.func
source tools.func

# Tool operations with error handling
# All errors are properly handled and explained
```

### With api.func

```bash
#!/usr/bin/env bash
# Integration with api.func

source core.func
source error_handler.func
source api.func

# API operations with error handling
# Network errors and API errors are properly handled
```

## Best Practices Examples

### Comprehensive Error Handling

```bash
#!/usr/bin/env bash
# Comprehensive error handling example

source error_handler.func

# Set up comprehensive error handling
setup_comprehensive_error_handling() {
    # Enable debug logging
    export DEBUG_LOGFILE="/tmp/script_debug.log"

    # Set up lock file
    lockfile="/tmp/script.lock"
    touch "$lockfile"

    # Initialize error handling
    catch_errors

    # Set up signal handlers
    trap on_interrupt INT
    trap on_terminate TERM
    trap on_exit EXIT

    echo "Comprehensive error handling configured"
}

setup_comprehensive_error_handling

# Script operations
echo "Starting script operations..."
# ... script code ...
echo "Script operations completed"
```

### Error Handling for Different Scenarios

```bash
#!/usr/bin/env bash
source error_handler.func

# Different error handling for different scenarios
handle_package_errors() {
    local exit_code=$1
    case "$exit_code" in
        100)
            echo "Package manager error - trying to fix..."
            apt-get --fix-broken install
            ;;
        101)
            echo "Configuration error - checking sources..."
            apt-get update
            ;;
        *)
            error_handler "$exit_code"
            ;;
    esac
}

handle_network_errors() {
    local exit_code=$1
    case "$exit_code" in
        127)
            echo "Network command not found - checking connectivity..."
            ping -c 1 8.8.8.8
            ;;
        *)
            error_handler "$exit_code"
            ;;
    esac
}

# Use appropriate error handler
if [[ "$1" == "package" ]]; then
    trap 'handle_package_errors $?' ERR
elif [[ "$1" == "network" ]]; then
    trap 'handle_network_errors $?' ERR
else
    catch_errors
fi
```

### Error Handling with Logging

```bash
#!/usr/bin/env bash
source error_handler.func

# Error handling with detailed logging
setup_logging_error_handling() {
    # Create log directory
    mkdir -p /var/log/script_errors

    # Set up debug logging
    export DEBUG_LOGFILE="/var/log/script_errors/debug.log"

    # Set up silent logging
    export SILENT_LOGFILE="/var/log/script_errors/silent.log"

    # Initialize error handling
    catch_errors

    echo "Logging error handling configured"
}

setup_logging_error_handling

# Script operations with logging
echo "Starting logged operations..."
# ... script code ...
echo "Logged operations completed"
```

## Troubleshooting Examples

### Debug Mode

```bash
#!/usr/bin/env bash
source error_handler.func

# Enable debug mode
export DEBUG_LOGFILE="/tmp/debug.log"
export STRICT_UNSET=1

catch_errors

echo "Debug mode enabled"
# Script operations
```

### Error Analysis

```bash
#!/usr/bin/env bash
source error_handler.func

# Function to analyze errors
analyze_errors() {
    local log_file="${1:-$DEBUG_LOGFILE}"

    if [[ -f "$log_file" ]]; then
        echo "Error Analysis:"
        echo "Total errors: $(grep -c "ERROR" "$log_file")"
        echo "Error types:"
        grep "ERROR" "$log_file" | awk '{print $NF}' | sort | uniq -c
        echo "Recent errors:"
        tail -n 10 "$log_file"
    else
        echo "No error log found"
    fi
}

# Run script with error analysis
analyze_errors
```

### Error Recovery Testing

```bash
#!/usr/bin/env bash
source error_handler.func

# Test error recovery
test_error_recovery() {
    local test_cases=(
        "nonexistent_command"
        "apt-get install nonexistent_package"
        "systemctl start nonexistent_service"
    )

    for test_case in "${test_cases[@]}"; do
        echo "Testing: $test_case"
        if silent $test_case; then
            echo "Unexpected success"
        else
            echo "Expected failure handled"
        fi
    done
}

test_error_recovery
```
