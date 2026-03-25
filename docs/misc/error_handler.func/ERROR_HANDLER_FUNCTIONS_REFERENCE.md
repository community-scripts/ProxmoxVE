# error_handler.func Functions Reference

## Overview

This document provides a comprehensive alphabetical reference of all functions in `error_handler.func`, including parameters, dependencies, usage examples, and error handling.

## Function Categories

### Error Explanation Functions

#### `explain_exit_code()`
**Purpose**: Convert numeric exit codes to human-readable explanations
**Parameters**:
- `$1` - Exit code to explain
**Returns**: Human-readable error explanation string
**Side Effects**: None
**Dependencies**: None
**Environment Variables Used**: None

**Supported Exit Codes**:
- **Generic/Shell**: 1, 2, 126, 127, 128, 130, 137, 139, 143
- **Package Manager**: 100, 101, 255
- **Node.js**: 243, 245, 246, 247, 248, 249, 254
- **Python**: 210, 211, 212
- **PostgreSQL**: 231, 232, 233, 234
- **MySQL/MariaDB**: 241, 242, 243, 244
- **MongoDB**: 251, 252, 253, 254
- **Proxmox Custom**: 200, 203, 204, 205, 209, 210, 214, 215, 216, 217, 220, 222, 223, 231

**Usage Example**:
```bash
explanation=$(explain_exit_code 127)
echo "Error 127: $explanation"
# Output: Error 127: Command not found
```

**Error Code Examples**:
```bash
explain_exit_code 1    # "General error / Operation not permitted"
explain_exit_code 126  # "Command invoked cannot execute (permission problem?)"
explain_exit_code 127  # "Command not found"
explain_exit_code 130  # "Terminated by Ctrl+C (SIGINT)"
explain_exit_code 200  # "Custom: Failed to create lock file"
explain_exit_code 999  # "Unknown error"
```

### Error Handling Functions

#### `error_handler()`
**Purpose**: Main error handler triggered by ERR trap or manual call
**Parameters**:
- `$1` - Exit code (optional, defaults to $?)
- `$2` - Command that failed (optional, defaults to BASH_COMMAND)
**Returns**: None (exits with error code)
**Side Effects**:
- Displays detailed error information
- Logs error to debug file if enabled
- Shows silent log content if available
- Exits with original error code
**Dependencies**: `explain_exit_code()`
**Environment Variables Used**: `DEBUG_LOGFILE`, `SILENT_LOGFILE`

**Usage Example**:
```bash
# Automatic error handling via ERR trap
set -e
trap 'error_handler' ERR

# Manual error handling
error_handler 127 "command_not_found"
```

**Error Information Displayed**:
- Error message with color coding
- Line number where error occurred
- Exit code with explanation
- Command that failed
- Silent log content (last 20 lines)
- Debug log entry (if enabled)

### Signal Handling Functions

#### `on_interrupt()`
**Purpose**: Handle SIGINT (Ctrl+C) signals gracefully
**Parameters**: None
**Returns**: None (exits with code 130)
**Side Effects**:
- Displays interruption message
- Exits with SIGINT code (130)
**Dependencies**: None
**Environment Variables Used**: None

**Usage Example**:
```bash
# Set up interrupt handler
trap on_interrupt INT

# User presses Ctrl+C
# Handler displays: "Interrupted by user (SIGINT)"
# Script exits with code 130
```

#### `on_terminate()`
**Purpose**: Handle SIGTERM signals gracefully
**Parameters**: None
**Returns**: None (exits with code 143)
**Side Effects**:
- Displays termination message
- Exits with SIGTERM code (143)
**Dependencies**: None
**Environment Variables Used**: None

**Usage Example**:
```bash
# Set up termination handler
trap on_terminate TERM

# System sends SIGTERM
# Handler displays: "Terminated by signal (SIGTERM)"
# Script exits with code 143
```

### Cleanup Functions

#### `on_exit()`
**Purpose**: Handle script exit cleanup
**Parameters**: None
**Returns**: None (exits with original exit code)
**Side Effects**:
- Removes lock file if set
- Exits with original exit code
**Dependencies**: None
**Environment Variables Used**: `lockfile`

**Usage Example**:
```bash
# Set up exit handler
trap on_exit EXIT

# Set lock file
lockfile="/tmp/my_script.lock"

# Script exits normally or with error
# Handler removes lock file and exits
```

### Initialization Functions

#### `catch_errors()`
**Purpose**: Initialize error handling traps and strict mode
**Parameters**: None
**Returns**: None
**Side Effects**:
- Sets strict error handling mode
- Sets up error traps
- Sets up signal traps
- Sets up exit trap
**Dependencies**: None
**Environment Variables Used**: `STRICT_UNSET`

**Strict Mode Settings**:
- `-E`: Exit on command failure
- `-e`: Exit on any error
- `-o pipefail`: Exit on pipe failure
- `-u`: Exit on unset variables (if STRICT_UNSET=1)

**Trap Setup**:
- `ERR`: Calls `error_handler` on command failure
- `EXIT`: Calls `on_exit` on script exit
- `INT`: Calls `on_interrupt` on SIGINT
- `TERM`: Calls `on_terminate` on SIGTERM

**Usage Example**:
```bash
# Initialize error handling
catch_errors

# Script now has full error handling
# All errors will be caught and handled
```

## Function Call Hierarchy

### Error Handling Flow
```
Command Failure
├── ERR trap triggered
├── error_handler() called
│   ├── Get exit code
│   ├── Get command info
│   ├── Get line number
│   ├── explain_exit_code()
│   ├── Display error info
│   ├── Log to debug file
│   ├── Show silent log
│   └── Exit with error code
```

### Signal Handling Flow
```
Signal Received
├── Signal trap triggered
├── Appropriate handler called
│   ├── on_interrupt() for SIGINT
│   ├── on_terminate() for SIGTERM
│   └── on_exit() for EXIT
└── Exit with signal code
```

### Initialization Flow
```
catch_errors()
├── Set strict mode
│   ├── -E (exit on failure)
│   ├── -e (exit on error)
│   ├── -o pipefail (pipe failure)
│   └── -u (unset variables, if enabled)
└── Set up traps
    ├── ERR → error_handler
    ├── EXIT → on_exit
    ├── INT → on_interrupt
    └── TERM → on_terminate
```

## Error Code Reference

### Generic/Shell Errors
| Code | Description |
|------|-------------|
| 1 | General error / Operation not permitted |
| 2 | Misuse of shell builtins (e.g. syntax error) |
| 126 | Command invoked cannot execute (permission problem?) |
| 127 | Command not found |
| 128 | Invalid argument to exit |
| 130 | Terminated by Ctrl+C (SIGINT) |
| 137 | Killed (SIGKILL / Out of memory?) |
| 139 | Segmentation fault (core dumped) |
| 143 | Terminated (SIGTERM) |

### Package Manager Errors
| Code | Description |
|------|-------------|
| 100 | APT: Package manager error (broken packages / dependency problems) |
| 101 | APT: Configuration error (bad sources.list, malformed config) |
| 255 | DPKG: Fatal internal error |

### Node.js Errors
| Code | Description |
|------|-------------|
| 243 | Node.js: Out of memory (JavaScript heap out of memory) |
| 245 | Node.js: Invalid command-line option |
| 246 | Node.js: Internal JavaScript Parse Error |
| 247 | Node.js: Fatal internal error |
| 248 | Node.js: Invalid C++ addon / N-API failure |
| 249 | Node.js: Inspector error |
| 254 | npm/pnpm/yarn: Unknown fatal error |

### Python Errors
| Code | Description |
|------|-------------|
| 210 | Python: Virtualenv / uv environment missing or broken |
| 211 | Python: Dependency resolution failed |
| 212 | Python: Installation aborted (permissions or EXTERNALLY-MANAGED) |

### Database Errors
| Code | Description |
|------|-------------|
| 231 | PostgreSQL: Connection failed (server not running / wrong socket) |
| 232 | PostgreSQL: Authentication failed (bad user/password) |
| 233 | PostgreSQL: Database does not exist |
| 234 | PostgreSQL: Fatal error in query / syntax |
| 241 | MySQL/MariaDB: Connection failed (server not running / wrong socket) |
| 242 | MySQL/MariaDB: Authentication failed (bad user/password) |
| 243 | MySQL/MariaDB: Database does not exist |
| 244 | MySQL/MariaDB: Fatal error in query / syntax |
| 251 | MongoDB: Connection failed (server not running) |
| 252 | MongoDB: Authentication failed (bad user/password) |
| 253 | MongoDB: Database not found |
| 254 | MongoDB: Fatal query error |

### Proxmox Custom Errors
| Code | Description |
|------|-------------|
| 200 | Custom: Failed to create lock file |
| 203 | Custom: Missing CTID variable |
| 204 | Custom: Missing PCT_OSTYPE variable |
| 205 | Custom: Invalid CTID (<100) |
| 209 | Custom: Container creation failed |
| 210 | Custom: Cluster not quorate |
| 214 | Custom: Not enough storage space |
| 215 | Custom: Container ID not listed |
| 216 | Custom: RootFS entry missing in config |
| 217 | Custom: Storage does not support rootdir |
| 220 | Custom: Unable to resolve template path |
| 222 | Custom: Template download failed after 3 attempts |
| 223 | Custom: Template not available after download |
| 231 | Custom: LXC stack upgrade/retry failed |

## Environment Variable Dependencies

### Required Variables
- **`lockfile`**: Lock file path for cleanup (set by calling script)

### Optional Variables
- **`DEBUG_LOGFILE`**: Path to debug log file for error logging
- **`SILENT_LOGFILE`**: Path to silent execution log file
- **`STRICT_UNSET`**: Enable strict unset variable checking (0/1)

### Internal Variables
- **`exit_code`**: Current exit code
- **`command`**: Failed command
- **`line_number`**: Line number where error occurred
- **`explanation`**: Error explanation text

## Error Handling Patterns

### Automatic Error Handling
```bash
#!/usr/bin/env bash
source error_handler.func

# Initialize error handling
catch_errors

# All commands are now monitored
# Errors will be automatically caught and handled
```

### Manual Error Handling
```bash
#!/usr/bin/env bash
source error_handler.func

# Manual error handling
if ! command -v required_tool >/dev/null 2>&1; then
    error_handler 127 "required_tool not found"
fi
```

### Custom Error Codes
```bash
#!/usr/bin/env bash
source error_handler.func

# Use custom error codes
if [[ ! -f /required/file ]]; then
    echo "Error: Required file missing"
    exit 200  # Custom error code
fi
```

### Signal Handling
```bash
#!/usr/bin/env bash
source error_handler.func

# Set up signal handling
trap on_interrupt INT
trap on_terminate TERM
trap on_exit EXIT

# Script handles signals gracefully
```

## Integration Examples

### With core.func
```bash
#!/usr/bin/env bash
source core.func
source error_handler.func

# Silent execution uses error_handler for explanations
silent apt-get install -y package
# If command fails, error_handler provides explanation
```

### With build.func
```bash
#!/usr/bin/env bash
source core.func
source error_handler.func
source build.func

# Container creation with error handling
# Errors are caught and explained
```

### With tools.func
```bash
#!/usr/bin/env bash
source core.func
source error_handler.func
source tools.func

# Tool operations with error handling
# All errors are properly handled and explained
```

## Best Practices

### Error Handling Setup
1. Source error_handler.func early in script
2. Call catch_errors() to initialize traps
3. Use appropriate exit codes for different error types
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

### Custom Error Codes
1. Use Proxmox custom error codes (200-231) for container/VM errors
2. Use standard error codes for common operations
3. Document custom error codes in script comments
4. Provide clear error messages for custom codes
