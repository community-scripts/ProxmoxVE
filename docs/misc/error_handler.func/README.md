# error_handler.func Documentation

## Overview

The `error_handler.func` file provides comprehensive error handling and signal management for Proxmox Community Scripts. It offers detailed error code explanations, graceful error recovery, and proper cleanup mechanisms.

## Purpose and Use Cases

- **Error Code Explanation**: Provides human-readable explanations for exit codes
- **Signal Handling**: Manages SIGINT, SIGTERM, and other signals gracefully
- **Error Recovery**: Implements proper cleanup and error reporting
- **Debug Logging**: Records error information for troubleshooting
- **Silent Execution Support**: Integrates with core.func silent execution

## Quick Reference

### Key Function Groups
- **Error Explanation**: `explain_exit_code()` - Convert exit codes to human-readable messages
- **Error Handling**: `error_handler()` - Main error handler with detailed reporting
- **Signal Handlers**: `on_interrupt()`, `on_terminate()` - Graceful signal handling
- **Cleanup**: `on_exit()` - Cleanup on script exit
- **Trap Setup**: `catch_errors()` - Initialize error handling traps

### Dependencies
- **External**: None (pure Bash implementation)
- **Internal**: Uses color variables from core.func

### Integration Points
- Used by: All scripts via core.func silent execution
- Uses: Color variables from core.func
- Provides: Error explanations for core.func silent function

## Documentation Files

### 📊 [ERROR_HANDLER_FLOWCHART.md](./ERROR_HANDLER_FLOWCHART.md)
Visual execution flows showing error handling processes and signal management.

### 📚 [ERROR_HANDLER_FUNCTIONS_REFERENCE.md](./ERROR_HANDLER_FUNCTIONS_REFERENCE.md)
Complete alphabetical reference of all functions with parameters, dependencies, and usage details.

### 💡 [ERROR_HANDLER_USAGE_EXAMPLES.md](./ERROR_HANDLER_USAGE_EXAMPLES.md)
Practical examples showing how to use error handling functions and common patterns.

### 🔗 [ERROR_HANDLER_INTEGRATION.md](./ERROR_HANDLER_INTEGRATION.md)
How error_handler.func integrates with other components and provides error handling services.

## Key Features

### Error Code Categories
- **Generic/Shell Errors**: Exit codes 1, 2, 126, 127, 128, 130, 137, 139, 143
- **Package Manager Errors**: APT/DPKG errors (100, 101, 255)
- **Node.js Errors**: JavaScript runtime errors (243-249, 254)
- **Python Errors**: Python environment and dependency errors (210-212)
- **Database Errors**: PostgreSQL, MySQL, MongoDB errors (231-254)
- **Proxmox Custom Errors**: Container and VM specific errors (200-231)

### Signal Handling
- **SIGINT (Ctrl+C)**: Graceful interruption handling
- **SIGTERM**: Graceful termination handling
- **EXIT**: Cleanup on script exit
- **ERR**: Error trap for command failures

### Error Reporting
- **Detailed Messages**: Human-readable error explanations
- **Context Information**: Line numbers, commands, timestamps
- **Log Integration**: Silent log file integration
- **Debug Logging**: Optional debug log file support

## Common Usage Patterns

### Basic Error Handling Setup
```bash
#!/usr/bin/env bash
# Basic error handling setup

source error_handler.func

# Initialize error handling
catch_errors

# Your script code here
# Errors will be automatically handled
```

### Manual Error Explanation
```bash
#!/usr/bin/env bash
source error_handler.func

# Get error explanation
explanation=$(explain_exit_code 127)
echo "Error 127: $explanation"
# Output: Error 127: Command not found
```

### Custom Error Handling
```bash
#!/usr/bin/env bash
source error_handler.func

# Custom error handling
if ! command -v required_tool >/dev/null 2>&1; then
    echo "Error: required_tool not found"
    exit 127
fi
```

## Environment Variables

### Debug Variables
- `DEBUG_LOGFILE`: Path to debug log file for error logging
- `SILENT_LOGFILE`: Path to silent execution log file
- `STRICT_UNSET`: Enable strict unset variable checking (0/1)

### Internal Variables
- `lockfile`: Lock file path for cleanup (set by calling script)
- `exit_code`: Current exit code
- `command`: Failed command
- `line_number`: Line number where error occurred

## Error Categories

### Generic/Shell Errors
- **1**: General error / Operation not permitted
- **2**: Misuse of shell builtins (syntax error)
- **126**: Command invoked cannot execute (permission problem)
- **127**: Command not found
- **128**: Invalid argument to exit
- **130**: Terminated by Ctrl+C (SIGINT)
- **137**: Killed (SIGKILL / Out of memory)
- **139**: Segmentation fault (core dumped)
- **143**: Terminated (SIGTERM)

### Package Manager Errors
- **100**: APT package manager error (broken packages)
- **101**: APT configuration error (bad sources.list)
- **255**: DPKG fatal internal error

### Node.js Errors
- **243**: JavaScript heap out of memory
- **245**: Invalid command-line option
- **246**: Internal JavaScript parse error
- **247**: Fatal internal error
- **248**: Invalid C++ addon / N-API failure
- **249**: Inspector error
- **254**: npm/pnpm/yarn unknown fatal error

### Python Errors
- **210**: Virtualenv/uv environment missing or broken
- **211**: Dependency resolution failed
- **212**: Installation aborted (permissions or EXTERNALLY-MANAGED)

### Database Errors
- **PostgreSQL (231-234)**: Connection, authentication, database, query errors
- **MySQL/MariaDB (241-244)**: Connection, authentication, database, query errors
- **MongoDB (251-254)**: Connection, authentication, database, query errors

### Proxmox Custom Errors
- **200**: Failed to create lock file
- **203**: Missing CTID variable
- **204**: Missing PCT_OSTYPE variable
- **205**: Invalid CTID (<100)
- **209**: Container creation failed
- **210**: Cluster not quorate
- **214**: Not enough storage space
- **215**: Container ID not listed
- **216**: RootFS entry missing in config
- **217**: Storage does not support rootdir
- **220**: Unable to resolve template path
- **222**: Template download failed after 3 attempts
- **223**: Template not available after download
- **231**: LXC stack upgrade/retry failed

## Best Practices

### Error Handling Setup
1. Source error_handler.func early in script
2. Call catch_errors() to initialize traps
3. Use proper exit codes for different error types
4. Provide meaningful error messages

### Signal Handling
1. Always set up signal traps
2. Provide graceful cleanup on interruption
3. Use appropriate exit codes for signals
4. Clean up temporary files and processes

### Error Reporting
1. Use explain_exit_code() for user-friendly messages
2. Log errors to debug files when needed
3. Provide context information (line numbers, commands)
4. Integrate with silent execution logging

## Troubleshooting

### Common Issues
1. **Missing Error Handler**: Ensure error_handler.func is sourced
2. **Trap Not Set**: Call catch_errors() to initialize traps
3. **Color Variables**: Ensure core.func is sourced for colors
4. **Lock Files**: Clean up lock files in on_exit()

### Debug Mode
Enable debug logging for detailed error information:
```bash
export DEBUG_LOGFILE="/tmp/debug.log"
source error_handler.func
catch_errors
```

### Error Code Testing
Test error explanations:
```bash
source error_handler.func
for code in 1 2 126 127 128 130 137 139 143; do
    echo "Code $code: $(explain_exit_code $code)"
done
```

## Related Documentation

- [core.func](../core.func/) - Core utilities and silent execution
- [build.func](../build.func/) - Container creation with error handling
- [tools.func](../tools.func/) - Extended utilities with error handling
- [api.func](../api.func/) - API operations with error handling

---

*This documentation covers the error_handler.func file which provides comprehensive error handling for all Proxmox Community Scripts.*
