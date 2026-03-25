# core.func Functions Reference

## Overview

This document provides a comprehensive alphabetical reference of all functions in `core.func`, including parameters, dependencies, usage examples, and error handling.

## Function Categories

### Initialization Functions

#### `load_functions()`
**Purpose**: Main function loader that initializes all core utilities
**Parameters**: None
**Returns**: None
**Side Effects**:
- Sets `__FUNCTIONS_LOADED=1` to prevent reloading
- Calls all core function groups in sequence
- Initializes color, formatting, icons, defaults, and standard mode
**Dependencies**: None
**Environment Variables Used**: `__FUNCTIONS_LOADED`

**Usage Example**:
```bash
# Automatically called when core.func is sourced
source core.func
# load_functions() is called automatically
```

### Color and Formatting Functions

#### `color()`
**Purpose**: Set ANSI color codes for styled terminal output
**Parameters**: None
**Returns**: None
**Side Effects**: Sets global color variables
**Dependencies**: None
**Environment Variables Used**: None

**Sets Variables**:
- `YW`: Yellow
- `YWB`: Bright yellow
- `BL`: Blue
- `RD`: Red
- `BGN`: Bright green
- `GN`: Green
- `DGN`: Dark green
- `CL`: Clear/reset

**Usage Example**:
```bash
color
echo -e "${GN}Success message${CL}"
echo -e "${RD}Error message${CL}"
```

#### `color_spinner()`
**Purpose**: Set color codes specifically for spinner output
**Parameters**: None
**Returns**: None
**Side Effects**: Sets spinner-specific color variables
**Dependencies**: None
**Environment Variables Used**: None

**Sets Variables**:
- `CS_YW`: Yellow for spinner
- `CS_YWB`: Bright yellow for spinner
- `CS_CL`: Clear for spinner

#### `formatting()`
**Purpose**: Define formatting helpers for terminal output
**Parameters**: None
**Returns**: None
**Side Effects**: Sets global formatting variables
**Dependencies**: None
**Environment Variables Used**: None

**Sets Variables**:
- `BFR`: Back and forward reset
- `BOLD`: Bold text
- `HOLD`: Space character
- `TAB`: Two spaces
- `TAB3`: Six spaces

### Icon Functions

#### `icons()`
**Purpose**: Set symbolic icons used throughout user feedback and prompts
**Parameters**: None
**Returns**: None
**Side Effects**: Sets global icon variables
**Dependencies**: `formatting()` (for TAB variable)
**Environment Variables Used**: `TAB`, `CL`

**Sets Variables**:
- `CM`: Check mark
- `CROSS`: Cross mark
- `DNSOK`: DNS success
- `DNSFAIL`: DNS failure
- `INFO`: Information icon
- `OS`: Operating system icon
- `OSVERSION`: OS version icon
- `CONTAINERTYPE`: Container type icon
- `DISKSIZE`: Disk size icon
- `CPUCORE`: CPU core icon
- `RAMSIZE`: RAM size icon
- `SEARCH`: Search icon
- `VERBOSE_CROPPED`: Verbose mode icon
- `VERIFYPW`: Password verification icon
- `CONTAINERID`: Container ID icon
- `HOSTNAME`: Hostname icon
- `BRIDGE`: Bridge icon
- `NETWORK`: Network icon
- `GATEWAY`: Gateway icon
- `DISABLEIPV6`: IPv6 disable icon
- `DEFAULT`: Default settings icon
- `MACADDRESS`: MAC address icon
- `VLANTAG`: VLAN tag icon
- `ROOTSSH`: SSH key icon
- `CREATING`: Creating icon
- `ADVANCED`: Advanced settings icon
- `FUSE`: FUSE icon
- `HOURGLASS`: Hourglass icon

### Default Variables Functions

#### `default_vars()`
**Purpose**: Set default retry and wait variables for system actions
**Parameters**: None
**Returns**: None
**Side Effects**: Sets retry configuration variables
**Dependencies**: None
**Environment Variables Used**: None

**Sets Variables**:
- `RETRY_NUM`: Number of retry attempts (default: 10)
- `RETRY_EVERY`: Seconds between retries (default: 3)
- `i`: Retry counter initialized to RETRY_NUM

#### `set_std_mode()`
**Purpose**: Set default verbose mode for script execution
**Parameters**: None
**Returns**: None
**Side Effects**: Sets STD variable based on VERBOSE setting
**Dependencies**: None
**Environment Variables Used**: `VERBOSE`

**Sets Variables**:
- `STD`: "silent" if VERBOSE != "yes", empty string if VERBOSE = "yes"

### Silent Execution Functions

#### `silent()`
**Purpose**: Execute commands silently with detailed error reporting
**Parameters**: `$*` - Command and arguments to execute
**Returns**: None (exits on error)
**Side Effects**:
- Executes command with output redirected to log file
- On error, displays detailed error information
- Exits with command's exit code
**Dependencies**: `error_handler.func` (for error explanations)
**Environment Variables Used**: `SILENT_LOGFILE`

**Usage Example**:
```bash
silent apt-get update
silent apt-get install -y package-name
```

**Error Handling**:
- Captures command output to `/tmp/silent.$$.log`
- Shows error code explanation
- Displays last 10 lines of log
- Provides command to view full log

### System Check Functions

#### `shell_check()`
**Purpose**: Verify that the script is running in Bash shell
**Parameters**: None
**Returns**: None (exits if not Bash)
**Side Effects**:
- Checks current shell process
- Exits with error message if not Bash
**Dependencies**: None
**Environment Variables Used**: None

**Usage Example**:
```bash
shell_check
# Script continues if Bash, exits if not
```

#### `root_check()`
**Purpose**: Ensure script is running as root user
**Parameters**: None
**Returns**: None (exits if not root)
**Side Effects**:
- Checks user ID and parent process
- Exits with error message if not root
**Dependencies**: None
**Environment Variables Used**: None

**Usage Example**:
```bash
root_check
# Script continues if root, exits if not
```

#### `pve_check()`
**Purpose**: Verify Proxmox VE version compatibility
**Parameters**: None
**Returns**: None (exits if unsupported version)
**Side Effects**:
- Checks PVE version using pveversion command
- Exits with error message if unsupported
**Dependencies**: `pveversion` command
**Environment Variables Used**: None

**Supported Versions**:
- Proxmox VE 8.0 - 8.9
- Proxmox VE 9.0 (only)

**Usage Example**:
```bash
pve_check
# Script continues if supported version, exits if not
```

#### `arch_check()`
**Purpose**: Verify system architecture is AMD64
**Parameters**: None
**Returns**: None (exits if not AMD64)
**Side Effects**:
- Checks system architecture
- Exits with PiMox warning if not AMD64
**Dependencies**: `dpkg` command
**Environment Variables Used**: None

**Usage Example**:
```bash
arch_check
# Script continues if AMD64, exits if not
```

#### `ssh_check()`
**Purpose**: Detect and warn about external SSH usage
**Parameters**: None
**Returns**: None
**Side Effects**:
- Checks SSH_CLIENT environment variable
- Warns if connecting from external IP
- Allows local connections (127.0.0.1 or host IP)
**Dependencies**: None
**Environment Variables Used**: `SSH_CLIENT`

**Usage Example**:
```bash
ssh_check
# Shows warning if external SSH, continues anyway
```

### Header Management Functions

#### `get_header()`
**Purpose**: Download and cache application header files
**Parameters**: None (uses APP and APP_TYPE variables)
**Returns**: Header content on success, empty on failure
**Side Effects**:
- Downloads header from remote URL
- Caches header locally
- Creates directory structure if needed
**Dependencies**: `curl` command
**Environment Variables Used**: `APP`, `APP_TYPE`

**Usage Example**:
```bash
export APP="plex"
export APP_TYPE="ct"
header_content=$(get_header)
```

#### `header_info()`
**Purpose**: Display application header information
**Parameters**: None (uses APP variable)
**Returns**: None
**Side Effects**:
- Clears screen
- Displays header content
- Gets terminal width for formatting
**Dependencies**: `get_header()`, `tput` command
**Environment Variables Used**: `APP`

**Usage Example**:
```bash
export APP="plex"
header_info
# Displays Plex header information
```

### Utility Functions

#### `ensure_tput()`
**Purpose**: Ensure tput command is available for terminal control
**Parameters**: None
**Returns**: None
**Side Effects**:
- Installs ncurses package if tput missing
- Works on Alpine and Debian-based systems
**Dependencies**: `apk` or `apt-get` package managers
**Environment Variables Used**: None

**Usage Example**:
```bash
ensure_tput
# Installs ncurses if needed, continues if already available
```

#### `is_alpine()`
**Purpose**: Detect if running on Alpine Linux
**Parameters**: None
**Returns**: 0 if Alpine, 1 if not Alpine
**Side Effects**: None
**Dependencies**: None
**Environment Variables Used**: `var_os`, `PCT_OSTYPE`

**Usage Example**:
```bash
if is_alpine; then
    echo "Running on Alpine Linux"
else
    echo "Not running on Alpine Linux"
fi
```

#### `is_verbose_mode()`
**Purpose**: Check if verbose mode is enabled
**Parameters**: None
**Returns**: 0 if verbose mode, 1 if not verbose
**Side Effects**: None
**Dependencies**: None
**Environment Variables Used**: `VERBOSE`, `var_verbose`

**Usage Example**:
```bash
if is_verbose_mode; then
    echo "Verbose mode enabled"
else
    echo "Verbose mode disabled"
fi
```

#### `fatal()`
**Purpose**: Display fatal error and terminate script
**Parameters**: `$1` - Error message
**Returns**: None (terminates script)
**Side Effects**:
- Displays error message
- Sends INT signal to current process
**Dependencies**: `msg_error()`
**Environment Variables Used**: None

**Usage Example**:
```bash
fatal "Critical error occurred"
# Script terminates after displaying error
```

### Spinner Functions

#### `spinner()`
**Purpose**: Display animated spinner for progress indication
**Parameters**: None (uses SPINNER_MSG variable)
**Returns**: None (runs indefinitely)
**Side Effects**:
- Displays rotating spinner characters
- Uses terminal control sequences
**Dependencies**: `color_spinner()`
**Environment Variables Used**: `SPINNER_MSG`

**Usage Example**:
```bash
SPINNER_MSG="Processing..."
spinner &
SPINNER_PID=$!
# Spinner runs in background
```

#### `clear_line()`
**Purpose**: Clear current terminal line
**Parameters**: None
**Returns**: None
**Side Effects**: Clears current line using terminal control
**Dependencies**: `tput` command
**Environment Variables Used**: None

#### `stop_spinner()`
**Purpose**: Stop running spinner and cleanup
**Parameters**: None
**Returns**: None
**Side Effects**:
- Kills spinner process
- Removes PID file
- Resets terminal settings
- Unsets spinner variables
**Dependencies**: None
**Environment Variables Used**: `SPINNER_PID`, `SPINNER_MSG`

**Usage Example**:
```bash
stop_spinner
# Stops spinner and cleans up
```

### Message Functions

#### `msg_info()`
**Purpose**: Display informational message with spinner
**Parameters**: `$1` - Message text
**Returns**: None
**Side Effects**:
- Starts spinner if not in verbose mode
- Tracks shown messages to prevent duplicates
- Displays message with hourglass icon in verbose mode
**Dependencies**: `spinner()`, `is_verbose_mode()`, `is_alpine()`
**Environment Variables Used**: `MSG_INFO_SHOWN`

**Usage Example**:
```bash
msg_info "Installing package..."
# Shows spinner with message
```

#### `msg_ok()`
**Purpose**: Display success message
**Parameters**: `$1` - Success message text
**Returns**: None
**Side Effects**:
- Stops spinner
- Displays green checkmark with message
- Removes message from shown tracking
**Dependencies**: `stop_spinner()`
**Environment Variables Used**: `MSG_INFO_SHOWN`

**Usage Example**:
```bash
msg_ok "Package installed successfully"
# Shows green checkmark with message
```

#### `msg_error()`
**Purpose**: Display error message
**Parameters**: `$1` - Error message text
**Returns**: None
**Side Effects**:
- Stops spinner
- Displays red cross with message
**Dependencies**: `stop_spinner()`
**Environment Variables Used**: None

**Usage Example**:
```bash
msg_error "Installation failed"
# Shows red cross with message
```

#### `msg_warn()`
**Purpose**: Display warning message
**Parameters**: `$1` - Warning message text
**Returns**: None
**Side Effects**:
- Stops spinner
- Displays yellow info icon with message
**Dependencies**: `stop_spinner()`
**Environment Variables Used**: None

**Usage Example**:
```bash
msg_warn "This operation may take some time"
# Shows yellow info icon with message
```

#### `msg_custom()`
**Purpose**: Display custom message with specified symbol and color
**Parameters**:
- `$1` - Custom symbol (default: "[*]")
- `$2` - Color code (default: "\e[36m")
- `$3` - Message text
**Returns**: None
**Side Effects**:
- Stops spinner
- Displays custom formatted message
**Dependencies**: `stop_spinner()`
**Environment Variables Used**: None

**Usage Example**:
```bash
msg_custom "⚡" "\e[33m" "Custom warning message"
# Shows custom symbol and color with message
```

#### `msg_debug()`
**Purpose**: Display debug message if debug mode enabled
**Parameters**: `$*` - Debug message text
**Returns**: None
**Side Effects**:
- Only displays if var_full_verbose is set
- Shows timestamp and debug prefix
**Dependencies**: None
**Environment Variables Used**: `var_full_verbose`, `var_verbose`

**Usage Example**:
```bash
export var_full_verbose=1
msg_debug "Debug information here"
# Shows debug message with timestamp
```

### System Management Functions

#### `check_or_create_swap()`
**Purpose**: Check for active swap and optionally create swap file
**Parameters**: None
**Returns**: 0 if swap exists or created, 1 if skipped
**Side Effects**:
- Checks for active swap
- Prompts user to create swap if none found
- Creates swap file if user confirms
**Dependencies**: `swapon`, `dd`, `mkswap` commands
**Environment Variables Used**: None

**Usage Example**:
```bash
if check_or_create_swap; then
    echo "Swap is available"
else
    echo "No swap available"
fi
```

## Function Call Hierarchy

### Initialization Flow
```
load_functions()
├── color()
├── formatting()
├── icons()
├── default_vars()
└── set_std_mode()
```

### Message System Flow
```
msg_info()
├── is_verbose_mode()
├── is_alpine()
├── spinner()
└── color_spinner()

msg_ok()
├── stop_spinner()
└── clear_line()

msg_error()
└── stop_spinner()

msg_warn()
└── stop_spinner()
```

### System Check Flow
```
pve_check()
├── pveversion command
└── version parsing

arch_check()
├── dpkg command
└── architecture check

shell_check()
├── ps command
└── shell detection

root_check()
├── id command
└── parent process check
```

### Silent Execution Flow
```
silent()
├── Command execution
├── Output redirection
├── Error handling
├── error_handler.func loading
└── Log management
```

## Error Handling Patterns

### System Check Errors
- All system check functions exit with appropriate error messages
- Clear indication of what's wrong and how to fix it
- Graceful exit with sleep delay for user to read message

### Silent Execution Errors
- Commands executed via `silent()` capture output to log file
- On failure, displays error code explanation
- Shows last 10 lines of log output
- Provides command to view full log

### Spinner Errors
- Spinner functions handle process cleanup on exit
- Trap handlers ensure spinners are stopped
- Terminal settings are restored on error

## Environment Variable Dependencies

### Required Variables
- `APP`: Application name for header display
- `APP_TYPE`: Application type (ct/vm) for header paths
- `VERBOSE`: Verbose mode setting

### Optional Variables
- `var_os`: OS type for Alpine detection
- `PCT_OSTYPE`: Alternative OS type variable
- `var_verbose`: Alternative verbose setting
- `var_full_verbose`: Debug mode setting

### Internal Variables
- `_CORE_FUNC_LOADED`: Prevents multiple loading
- `__FUNCTIONS_LOADED`: Prevents multiple function loading
- `SILENT_LOGFILE`: Silent execution log file path
- `SPINNER_PID`: Spinner process ID
- `SPINNER_MSG`: Spinner message text
- `MSG_INFO_SHOWN`: Tracks shown info messages
