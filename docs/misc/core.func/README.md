# core.func Documentation

## Overview

The `core.func` file provides fundamental utility functions and system checks that form the foundation for all other scripts in the Proxmox Community Scripts project. It handles basic system operations, user interface elements, validation, and core infrastructure.

## Purpose and Use Cases

- **System Validation**: Checks for Proxmox VE compatibility, architecture, shell requirements
- **User Interface**: Provides colored output, icons, spinners, and formatted messages
- **Core Utilities**: Basic functions used across all scripts
- **Error Handling**: Silent execution with detailed error reporting
- **System Information**: OS detection, verbose mode handling, swap management

## Quick Reference

### Key Function Groups
- **System Checks**: `pve_check()`, `arch_check()`, `shell_check()`, `root_check()`
- **User Interface**: `msg_info()`, `msg_ok()`, `msg_error()`, `msg_warn()`, `spinner()`
- **Core Utilities**: `silent()`, `is_alpine()`, `is_verbose_mode()`, `get_header()`
- **System Management**: `check_or_create_swap()`, `ensure_tput()`

### Dependencies
- **External**: `curl` for downloading headers, `tput` for terminal control
- **Internal**: `error_handler.func` for error explanations

### Integration Points
- Used by: All other `.func` files and installation scripts
- Uses: `error_handler.func` for error explanations
- Provides: Core utilities for `build.func`, `tools.func`, `api.func`

## Documentation Files

### 📊 [CORE_FLOWCHART.md](./CORE_FLOWCHART.md)
Visual execution flows showing how core functions interact and the system validation process.

### 📚 [CORE_FUNCTIONS_REFERENCE.md](./CORE_FUNCTIONS_REFERENCE.md)
Complete alphabetical reference of all functions with parameters, dependencies, and usage details.

### 💡 [CORE_USAGE_EXAMPLES.md](./CORE_USAGE_EXAMPLES.md)
Practical examples showing how to use core functions in scripts and common patterns.

### 🔗 [CORE_INTEGRATION.md](./CORE_INTEGRATION.md)
How core.func integrates with other components and provides foundational services.

## Key Features

### System Validation
- **Proxmox VE Version Check**: Supports PVE 8.0-8.9 and 9.0
- **Architecture Check**: Ensures AMD64 architecture (excludes PiMox)
- **Shell Check**: Validates Bash shell usage
- **Root Check**: Ensures root privileges
- **SSH Check**: Warns about external SSH usage

### User Interface
- **Colored Output**: ANSI color codes for styled terminal output
- **Icons**: Symbolic icons for different message types
- **Spinners**: Animated progress indicators
- **Formatted Messages**: Consistent message formatting across scripts

### Core Utilities
- **Silent Execution**: Execute commands with detailed error reporting
- **OS Detection**: Alpine Linux detection
- **Verbose Mode**: Handle verbose output settings
- **Header Management**: Download and display application headers
- **Swap Management**: Check and create swap files

## Common Usage Patterns

### Basic Script Setup
```bash
# Source core functions
source core.func

# Run system checks
pve_check
arch_check
shell_check
root_check
```

### Message Display
```bash
# Show progress
msg_info "Installing package..."

# Show success
msg_ok "Package installed successfully"

# Show error
msg_error "Installation failed"

# Show warning
msg_warn "This operation may take some time"
```

### Silent Command Execution
```bash
# Execute command silently with error handling
silent apt-get update
silent apt-get install -y package-name
```

## Environment Variables

### Core Variables
- `VERBOSE`: Enable verbose output mode
- `SILENT_LOGFILE`: Path to silent execution log file
- `APP`: Application name for header display
- `APP_TYPE`: Application type (ct/vm) for header paths

### Internal Variables
- `_CORE_FUNC_LOADED`: Prevents multiple loading
- `__FUNCTIONS_LOADED`: Prevents multiple function loading
- `RETRY_NUM`: Number of retry attempts (default: 10)
- `RETRY_EVERY`: Seconds between retries (default: 3)

## Error Handling

### Silent Execution Errors
- Commands executed via `silent()` capture output to log file
- On failure, displays error code explanation
- Shows last 10 lines of log output
- Provides command to view full log

### System Check Failures
- Each system check function exits with appropriate error message
- Clear indication of what's wrong and how to fix it
- Graceful exit with sleep delay for user to read message

## Best Practices

### Script Initialization
1. Source `core.func` first
2. Run system checks early
3. Set up error handling
4. Use appropriate message functions

### Message Usage
1. Use `msg_info()` for progress updates
2. Use `msg_ok()` for successful completions
3. Use `msg_error()` for failures
4. Use `msg_warn()` for warnings

### Silent Execution
1. Use `silent()` for commands that might fail
2. Check return codes after silent execution
3. Provide meaningful error messages

## Troubleshooting

### Common Issues
1. **Proxmox Version**: Ensure running supported PVE version
2. **Architecture**: Script only works on AMD64 systems
3. **Shell**: Must use Bash shell
4. **Permissions**: Must run as root
5. **Network**: SSH warnings for external connections

### Debug Mode
Enable verbose output for debugging:
```bash
export VERBOSE="yes"
source core.func
```

### Log Files
Check silent execution logs:
```bash
cat /tmp/silent.$$.log
```

## Related Documentation

- [build.func](../build.func/) - Main container creation script
- [error_handler.func](../error_handler.func/) - Error handling utilities
- [tools.func](../tools.func/) - Extended utility functions
- [api.func](../api.func/) - Proxmox API interactions

---

*This documentation covers the core.func file which provides fundamental utilities for all Proxmox Community Scripts.*
