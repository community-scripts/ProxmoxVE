# api.func Functions Reference

## Overview

This document provides a comprehensive alphabetical reference of all functions in `api.func`, including parameters, dependencies, usage examples, and error handling.

## Function Categories

### Error Description Functions

#### `get_error_description()`
**Purpose**: Convert numeric exit codes to human-readable explanations
**Parameters**:
- `$1` - Exit code to explain
**Returns**: Human-readable error explanation string
**Side Effects**: None
**Dependencies**: None
**Environment Variables Used**: None

**Supported Exit Codes**:
- **General System**: 0-9, 18, 22, 28, 35, 56, 60, 125-128, 129-143, 152, 255
- **LXC-Specific**: 100-101, 200-209
- **Docker**: 125

**Usage Example**:
```bash
error_msg=$(get_error_description 127)
echo "Error 127: $error_msg"
# Output: Error 127: Command not found: Incorrect path or missing dependency.
```

**Error Code Examples**:
```bash
get_error_description 0     # " " (space)
get_error_description 1     # "General error: An unspecified error occurred."
get_error_description 127   # "Command not found: Incorrect path or missing dependency."
get_error_description 200   # "LXC creation failed."
get_error_description 255   # "Unknown critical error, often due to missing permissions or broken scripts."
```

### API Communication Functions

#### `post_to_api()`
**Purpose**: Send LXC container installation data to community-scripts.org API
**Parameters**: None (uses environment variables)
**Returns**: None
**Side Effects**:
- Sends HTTP POST request to API
- Stores response in RESPONSE variable
- Requires curl command and network connectivity
**Dependencies**: `curl` command
**Environment Variables Used**: `DIAGNOSTICS`, `RANDOM_UUID`, `CT_TYPE`, `DISK_SIZE`, `CORE_COUNT`, `RAM_SIZE`, `var_os`, `var_version`, `DISABLEIP6`, `NSAPP`, `METHOD`

**Prerequisites**:
- `curl` command must be available
- `DIAGNOSTICS` must be set to "yes"
- `RANDOM_UUID` must be set and not empty

**API Endpoint**: `https://api.community-scripts.org/dev/upload`

**JSON Payload Structure**:
```json
{
    "ct_type": 1,
    "type": "lxc",
    "disk_size": 8,
    "core_count": 2,
    "ram_size": 2048,
    "os_type": "debian",
    "os_version": "12",
    "disableip6": "true",
    "nsapp": "plex",
    "method": "install",
    "pve_version": "8.0",
    "status": "installing",
    "random_id": "uuid-string"
}
```

**Usage Example**:
```bash
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"
export CT_TYPE=1
export DISK_SIZE=8
export CORE_COUNT=2
export RAM_SIZE=2048
export var_os="debian"
export var_version="12"
export NSAPP="plex"
export METHOD="install"

post_to_api
```

#### `post_to_api_vm()`
**Purpose**: Send VM installation data to community-scripts.org API
**Parameters**: None (uses environment variables)
**Returns**: None
**Side Effects**:
- Sends HTTP POST request to API
- Stores response in RESPONSE variable
- Requires curl command and network connectivity
**Dependencies**: `curl` command, diagnostics file
**Environment Variables Used**: `DIAGNOSTICS`, `RANDOM_UUID`, `DISK_SIZE`, `CORE_COUNT`, `RAM_SIZE`, `var_os`, `var_version`, `NSAPP`, `METHOD`

**Prerequisites**:
- `/usr/local/community-scripts/diagnostics` file must exist
- `DIAGNOSTICS` must be set to "yes" in diagnostics file
- `curl` command must be available
- `RANDOM_UUID` must be set and not empty

**API Endpoint**: `https://api.community-scripts.org/dev/upload`

**JSON Payload Structure**:
```json
{
    "ct_type": 2,
    "type": "vm",
    "disk_size": 8,
    "core_count": 2,
    "ram_size": 2048,
    "os_type": "debian",
    "os_version": "12",
    "disableip6": "",
    "nsapp": "plex",
    "method": "install",
    "pve_version": "8.0",
    "status": "installing",
    "random_id": "uuid-string"
}
```

**Usage Example**:
```bash
# Create diagnostics file
echo "DIAGNOSTICS=yes" > /usr/local/community-scripts/diagnostics

export RANDOM_UUID="$(uuidgen)"
export DISK_SIZE="8G"
export CORE_COUNT=2
export RAM_SIZE=2048
export var_os="debian"
export var_version="12"
export NSAPP="plex"
export METHOD="install"

post_to_api_vm
```

#### `post_update_to_api()`
**Purpose**: Send installation completion status to community-scripts.org API
**Parameters**:
- `$1` - Status ("success" or "failed", default: "failed")
- `$2` - Exit code (default: 1)
**Returns**: None
**Side Effects**:
- Sends HTTP POST request to API
- Sets POST_UPDATE_DONE=true to prevent duplicates
- Stores response in RESPONSE variable
**Dependencies**: `curl` command, `get_error_description()`
**Environment Variables Used**: `DIAGNOSTICS`, `RANDOM_UUID`

**Prerequisites**:
- `curl` command must be available
- `DIAGNOSTICS` must be set to "yes"
- `RANDOM_UUID` must be set and not empty
- POST_UPDATE_DONE must be false (prevents duplicates)

**API Endpoint**: `https://api.community-scripts.org/dev/upload/updatestatus`

**JSON Payload Structure**:
```json
{
    "status": "success",
    "error": "Error description from get_error_description()",
    "random_id": "uuid-string"
}
```

**Usage Example**:
```bash
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# Report successful installation
post_update_to_api "success" 0

# Report failed installation
post_update_to_api "failed" 127
```

## Function Call Hierarchy

### API Communication Flow
```
post_to_api()
├── Check curl availability
├── Check DIAGNOSTICS setting
├── Check RANDOM_UUID
├── Get PVE version
├── Create JSON payload
└── Send HTTP POST request

post_to_api_vm()
├── Check diagnostics file
├── Check curl availability
├── Check DIAGNOSTICS setting
├── Check RANDOM_UUID
├── Process disk size
├── Get PVE version
├── Create JSON payload
└── Send HTTP POST request

post_update_to_api()
├── Check POST_UPDATE_DONE flag
├── Check curl availability
├── Check DIAGNOSTICS setting
├── Check RANDOM_UUID
├── Determine status and exit code
├── Get error description
├── Create JSON payload
├── Send HTTP POST request
└── Set POST_UPDATE_DONE=true
```

### Error Description Flow
```
get_error_description()
├── Match exit code
├── Return appropriate description
└── Handle unknown codes
```

## Error Code Reference

### General System Errors
| Code | Description |
|------|-------------|
| 0 | (space) |
| 1 | General error: An unspecified error occurred. |
| 2 | Incorrect shell usage or invalid command arguments. |
| 3 | Unexecuted function or invalid shell condition. |
| 4 | Error opening a file or invalid path. |
| 5 | I/O error: An input/output failure occurred. |
| 6 | No such device or address. |
| 7 | Insufficient memory or resource exhaustion. |
| 8 | Non-executable file or invalid file format. |
| 9 | Failed child process execution. |
| 18 | Connection to a remote server failed. |
| 22 | Invalid argument or faulty network connection. |
| 28 | No space left on device. |
| 35 | Timeout while establishing a connection. |
| 56 | Faulty TLS connection. |
| 60 | SSL certificate error. |

### Command Execution Errors
| Code | Description |
|------|-------------|
| 125 | Docker error: Container could not start. |
| 126 | Command not executable: Incorrect permissions or missing dependencies. |
| 127 | Command not found: Incorrect path or missing dependency. |
| 128 | Invalid exit signal, e.g., incorrect Git command. |

### Signal Errors
| Code | Description |
|------|-------------|
| 129 | Signal 1 (SIGHUP): Process terminated due to hangup. |
| 130 | Signal 2 (SIGINT): Manual termination via Ctrl+C. |
| 132 | Signal 4 (SIGILL): Illegal machine instruction. |
| 133 | Signal 5 (SIGTRAP): Debugging error or invalid breakpoint signal. |
| 134 | Signal 6 (SIGABRT): Program aborted itself. |
| 135 | Signal 7 (SIGBUS): Memory error, invalid memory address. |
| 137 | Signal 9 (SIGKILL): Process forcibly terminated (OOM-killer or 'kill -9'). |
| 139 | Signal 11 (SIGSEGV): Segmentation fault, possibly due to invalid pointer access. |
| 141 | Signal 13 (SIGPIPE): Pipe closed unexpectedly. |
| 143 | Signal 15 (SIGTERM): Process terminated normally. |
| 152 | Signal 24 (SIGXCPU): CPU time limit exceeded. |

### LXC-Specific Errors
| Code | Description |
|------|-------------|
| 100 | LXC install error: Unexpected error in create_lxc.sh. |
| 101 | LXC install error: No network connection detected. |
| 200 | LXC creation failed. |
| 201 | LXC error: Invalid Storage class. |
| 202 | User aborted menu in create_lxc.sh. |
| 203 | CTID not set in create_lxc.sh. |
| 204 | PCT_OSTYPE not set in create_lxc.sh. |
| 205 | CTID cannot be less than 100 in create_lxc.sh. |
| 206 | CTID already in use in create_lxc.sh. |
| 207 | Template not found in create_lxc.sh. |
| 208 | Error downloading template in create_lxc.sh. |
| 209 | Container creation failed, but template is intact in create_lxc.sh. |

### Other Errors
| Code | Description |
|------|-------------|
| 255 | Unknown critical error, often due to missing permissions or broken scripts. |
| * | Unknown error code (exit_code). |

## Environment Variable Dependencies

### Required Variables
- **`DIAGNOSTICS`**: Enable/disable diagnostic reporting ("yes"/"no")
- **`RANDOM_UUID`**: Unique identifier for tracking

### Optional Variables
- **`CT_TYPE`**: Container type (1 for LXC, 2 for VM)
- **`DISK_SIZE`**: Disk size in GB (or GB with 'G' suffix for VM)
- **`CORE_COUNT`**: Number of CPU cores
- **`RAM_SIZE`**: RAM size in MB
- **`var_os`**: Operating system type
- **`var_version`**: OS version
- **`DISABLEIP6`**: IPv6 disable setting
- **`NSAPP`**: Namespace application name
- **`METHOD`**: Installation method

### Internal Variables
- **`POST_UPDATE_DONE`**: Prevents duplicate status updates
- **`API_URL`**: Community scripts API endpoint
- **`JSON_PAYLOAD`**: API request payload
- **`RESPONSE`**: API response
- **`DISK_SIZE_API`**: Processed disk size for VM API

## Error Handling Patterns

### API Communication Errors
- All API functions handle curl failures gracefully
- Network errors don't block installation process
- Missing prerequisites cause early return
- Duplicate updates are prevented

### Error Description Errors
- Unknown error codes return generic message
- All error codes are handled with case statement
- Fallback message includes the actual error code

### Prerequisites Validation
- Check curl availability before API calls
- Validate DIAGNOSTICS setting
- Ensure RANDOM_UUID is set
- Check for duplicate updates

## Integration Examples

### With build.func
```bash
#!/usr/bin/env bash
source core.func
source api.func
source build.func

# Set up API reporting
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# Report installation start
post_to_api

# Container creation...
# ... build.func code ...

# Report completion
if [[ $? -eq 0 ]]; then
    post_update_to_api "success" 0
else
    post_update_to_api "failed" $?
fi
```

### With vm-core.func
```bash
#!/usr/bin/env bash
source core.func
source api.func
source vm-core.func

# Set up API reporting
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# Report VM installation start
post_to_api_vm

# VM creation...
# ... vm-core.func code ...

# Report completion
post_update_to_api "success" 0
```

### With error_handler.func
```bash
#!/usr/bin/env bash
source core.func
source error_handler.func
source api.func

# Use error descriptions
error_code=127
error_msg=$(get_error_description $error_code)
echo "Error $error_code: $error_msg"

# Report error to API
post_update_to_api "failed" $error_code
```

## Best Practices

### API Usage
1. Always check prerequisites before API calls
2. Use unique identifiers for tracking
3. Handle API failures gracefully
4. Don't block installation on API failures

### Error Reporting
1. Use appropriate error codes
2. Provide meaningful error descriptions
3. Report both success and failure cases
4. Prevent duplicate status updates

### Diagnostic Reporting
1. Respect user privacy settings
2. Only send data when diagnostics enabled
3. Use anonymous tracking identifiers
4. Include relevant system information

### Error Handling
1. Handle unknown error codes gracefully
2. Provide fallback error messages
3. Include error code in unknown error messages
4. Use consistent error message format
