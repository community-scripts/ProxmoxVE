# Technical Reference: Configuration System Architecture

> **For Developers and Advanced Users**
> 
> *Deep dive into how the defaults and configuration system works*

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [File Format Specifications](#file-format-specifications)
3. [Function Reference](#function-reference)
4. [Variable Precedence](#variable-precedence)
5. [Data Flow Diagrams](#data-flow-diagrams)
6. [Security Model](#security-model)
7. [Implementation Details](#implementation-details)

---

## System Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Installation Script                       │
│  (pihole-install.sh, docker-install.sh, etc.)              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     v
┌─────────────────────────────────────────────────────────────┐
│                   build.func Library                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  variables()                                         │   │
│  │  - Initialize NSAPP, var_install, etc.             │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  install_script()                                    │   │
│  │  - Display mode menu                                │   │
│  │  - Route to appropriate workflow                    │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  base_settings()                                     │   │
│  │  - Apply built-in defaults                          │   │
│  │  - Read environment variables (var_*)               │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  load_vars_file()                                    │   │
│  │  - Safe file parsing (NO source/eval)              │   │
│  │  - Whitelist validation                             │   │
│  │  - Value sanitization                               │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  default_var_settings()                              │   │
│  │  - Load user defaults                               │   │
│  │  - Display summary                                  │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  maybe_offer_save_app_defaults()                     │   │
│  │  - Offer to save current settings                   │   │
│  │  - Handle updates vs. new saves                     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                     │
                     v
┌─────────────────────────────────────────────────────────────┐
│           Configuration Files (on Disk)                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  /usr/local/community-scripts/default.vars          │   │
│  │  (User global defaults)                             │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  /usr/local/community-scripts/defaults/*.vars       │   │
│  │  (App-specific defaults)                            │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## File Format Specifications

### User Defaults: `default.vars`

**Location**: `/usr/local/community-scripts/default.vars`

**MIME Type**: `text/plain`

**Encoding**: UTF-8 (no BOM)

**Format Specification**:

```
# File Format: Simple key=value pairs
# Purpose: Store global user defaults
# Security: Sanitized values, whitelist validation

# Comments and blank lines are ignored
# Line format: var_name=value
# No spaces around the equals sign
# String values do not need quoting (but may be quoted)

[CONTENT]
var_cpu=4
var_ram=2048
var_disk=20
var_hostname=mydefault
var_brg=vmbr0
var_gateway=192.168.1.1
```

**Formal Grammar**:

```
FILE       := (BLANK_LINE | COMMENT_LINE | VAR_LINE)*
BLANK_LINE := \n
COMMENT_LINE := '#' [^\n]* \n
VAR_LINE   := VAR_NAME '=' VAR_VALUE \n
VAR_NAME   := 'var_' [a-z_]+
VAR_VALUE  := [^\n]*  # Any printable characters except newline
```

**Constraints**:

| Constraint | Value |
|-----------|-------|
| Max file size | 64 KB |
| Max line length | 1024 bytes |
| Max variables | 100 |
| Allowed var names | `var_[a-z_]+` |
| Value validation | Whitelist + Sanitization |

**Example Valid File**:

```bash
# Global User Defaults
# Created: 2024-11-28

# Resource defaults
var_cpu=4
var_ram=2048
var_disk=20

# Network defaults
var_brg=vmbr0
var_gateway=192.168.1.1
var_mtu=1500
var_vlan=100

# System defaults
var_timezone=Europe/Berlin
var_hostname=default-container

# Storage
var_container_storage=local
var_template_storage=local

# Security
var_ssh=yes
var_protection=0
var_unprivileged=1
```

### App Defaults: `<app>.vars`

**Location**: `/usr/local/community-scripts/defaults/<appname>.vars`

**Format**: Identical to `default.vars`

**Naming Convention**: `<nsapp>.vars`

- `nsapp` = lowercase app name with spaces removed
- Examples:
  - `pihole` → `pihole.vars`
  - `opnsense` → `opnsense.vars`
  - `docker compose` → `dockercompose.vars`

**Example App Defaults**:

```bash
# App-specific defaults for PiHole (pihole)
# Generated on 2024-11-28T15:32:00Z
# These override user defaults when installing pihole

var_unprivileged=1
var_cpu=2
var_ram=1024
var_disk=10
var_brg=vmbr0
var_net=veth
var_gateway=192.168.1.1
var_hostname=pihole
var_timezone=Europe/Berlin
var_container_storage=local
var_template_storage=local
var_tags=dns,pihole
```

---

## Function Reference

### `load_vars_file()`

**Purpose**: Safely load variables from .vars files without using `source` or `eval`

**Signature**:
```bash
load_vars_file(filepath)
```

**Parameters**:

| Param | Type | Required | Example |
|-------|------|----------|---------|
| filepath | String | Yes | `/usr/local/community-scripts/default.vars` |

**Returns**:
- `0` on success
- `1` on error (file missing, parse error, etc.)

**Environment Side Effects**:
- Sets all parsed `var_*` variables as shell variables
- Does NOT unset variables if file missing (safe)
- Does NOT affect other variables

**Implementation Pattern**:

```bash
load_vars_file() {
  local file="$1"
  
  # File must exist
  [ -f "$file" ] || return 0
  
  # Parse line by line (not with source/eval)
  local line key val
  while IFS='=' read -r key val || [ -n "$key" ]; do
    # Skip comments and empty lines
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$key" ]] && continue
    
    # Validate key is in whitelist
    _is_whitelisted_key "$key" || continue
    
    # Sanitize and export value
    val="$(_sanitize_value "$val")"
    [ $? -eq 0 ] && export "$key=$val"
  done < "$file"
  
  return 0
}
```

**Usage Examples**:

```bash
# Load user defaults
load_vars_file "/usr/local/community-scripts/default.vars"

# Load app-specific defaults
load_vars_file "$(get_app_defaults_path)"

# Check if successful
if load_vars_file "$vars_path"; then
  echo "Settings loaded successfully"
else
  echo "Failed to load settings"
fi

# Values are now available as variables
echo "Using $var_cpu cores"
echo "Allocating ${var_ram} MB RAM"
```

---

### `get_app_defaults_path()`

**Purpose**: Get the full path for app-specific defaults file

**Signature**:
```bash
get_app_defaults_path()
```

**Parameters**: None

**Returns**:
- String: Full path to app defaults file

**Implementation**:

```bash
get_app_defaults_path() {
  local n="${NSAPP:-${APP,,}}"
  echo "/usr/local/community-scripts/defaults/${n}.vars"
}
```

**Usage Examples**:

```bash
# Get app defaults path
app_defaults="$(get_app_defaults_path)"
echo "App defaults at: $app_defaults"

# Check if app defaults exist
if [ -f "$(get_app_defaults_path)" ]; then
  echo "App defaults available"
fi

# Load app defaults
load_vars_file "$(get_app_defaults_path)"
```

---

### `default_var_settings()`

**Purpose**: Load and display user global defaults

**Signature**:
```bash
default_var_settings()
```

**Parameters**: None

**Returns**:
- `0` on success
- `1` on error

**Workflow**:

```
1. Find default.vars location
   (usually /usr/local/community-scripts/default.vars)
   
2. Create if missing
   
3. Load variables from file
   
4. Map var_verbose → VERBOSE variable
   
5. Call base_settings (apply to container config)
   
6. Call echo_default (display summary)
```

**Implementation Pattern**:

```bash
default_var_settings() {
  local VAR_WHITELIST=(
    var_apt_cacher var_apt_cacher_ip var_brg var_cpu var_disk var_fuse
    var_gateway var_hostname var_ipv6_method var_mac var_mtu
    var_net var_ns var_pw var_ram var_tags var_tun var_unprivileged
    var_verbose var_vlan var_ssh var_ssh_authorized_key
    var_container_storage var_template_storage
  )
  
  # Ensure file exists
  _ensure_default_vars
  
  # Find and load
  local dv="$(_find_default_vars)"
  load_vars_file "$dv"
  
  # Map verbose flag
  if [[ -n "${var_verbose:-}" ]]; then
    case "${var_verbose,,}" in
      1 | yes | true | on) VERBOSE="yes" ;;
      *) VERBOSE="${var_verbose}" ;;
    esac
  fi
  
  # Apply and display
  base_settings "$VERBOSE"
  echo_default
}
```

---

### `maybe_offer_save_app_defaults()`

**Purpose**: Offer to save current settings as app-specific defaults

**Signature**:
```bash
maybe_offer_save_app_defaults()
```

**Parameters**: None

**Returns**: None (side effects only)

**Behavior**:

1. After advanced installation completes
2. Offers user: "Save as App Defaults for <APP>?"
3. If yes:
   - Saves to `/usr/local/community-scripts/defaults/<app>.vars`
   - Only whitelisted variables included
   - Previous defaults backed up (if exists)
4. If no:
   - No action taken

**Flow**:

```bash
maybe_offer_save_app_defaults() {
  local app_vars_path="$(get_app_defaults_path)"
  
  # Build current settings from memory
  local new_tmp="$(_build_current_app_vars_tmp)"
  
  # Check if already exists
  if [ -f "$app_vars_path" ]; then
    # Show diff and ask: Update? Keep? View Diff?
    _show_app_defaults_diff_menu "$new_tmp" "$app_vars_path"
  else
    # New defaults - just save
    if whiptail --yesno "Save as App Defaults for $APP?" 10 60; then
      mv "$new_tmp" "$app_vars_path"
      chmod 644 "$app_vars_path"
    fi
  fi
}
```

---

### `_sanitize_value()`

**Purpose**: Remove dangerous characters/patterns from configuration values

**Signature**:
```bash
_sanitize_value(value)
```

**Parameters**:

| Param | Type | Required |
|-------|------|----------|
| value | String | Yes |

**Returns**:
- `0` (success) + sanitized value on stdout
- `1` (failure) + nothing if dangerous

**Dangerous Patterns**:

| Pattern | Threat | Example |
|---------|--------|---------|
| `$(...)` | Command substitution | `$(rm -rf /)` |
| `` ` ` `` | Command substitution | `` `whoami` `` |
| `;` | Command separator | `value; rm -rf /` |
| `&` | Background execution | `value & malicious` |
| `<(` | Process substitution | `<(cat /etc/passwd)` |

**Implementation**:

```bash
_sanitize_value() {
  case "$1" in
  *'$('* | *'`'* | *';'* | *'&'* | *'<('*)
    echo ""
    return 1  # Reject dangerous value
    ;;
  esac
  echo "$1"
  return 0
}
```

**Usage Examples**:

```bash
# Safe value
_sanitize_value "192.168.1.1"  # Returns: 192.168.1.1 (status: 0)

# Dangerous value
_sanitize_value "$(whoami)"     # Returns: (empty) (status: 1)

# Usage in code
if val="$(_sanitize_value "$user_input")"; then
  export var_hostname="$val"
else
  msg_error "Invalid value: contains dangerous characters"
fi
```

---

### `_is_whitelisted_key()`

**Purpose**: Check if variable name is in allowed whitelist

**Signature**:
```bash
_is_whitelisted_key(key)
```

**Parameters**:

| Param | Type | Required | Example |
|-------|------|----------|---------|
| key | String | Yes | `var_cpu` |

**Returns**:
- `0` if key is whitelisted
- `1` if key is NOT whitelisted

**Implementation**:

```bash
_is_whitelisted_key() {
  local k="$1"
  local w
  for w in "${VAR_WHITELIST[@]}"; do
    [ "$k" = "$w" ] && return 0
  done
  return 1
}
```

**Usage Examples**:

```bash
# Check if variable can be saved
if _is_whitelisted_key "var_cpu"; then
  echo "var_cpu can be saved"
fi

# Reject unknown variables
if ! _is_whitelisted_key "var_custom"; then
  msg_error "var_custom is not supported"
fi
```

---

## Variable Precedence

### Loading Order

When a container is being created, variables are resolved in this order:

```
Step 1: Read ENVIRONMENT VARIABLES
   ├─ Check if var_cpu is already set in shell environment
   ├─ Check if var_ram is already set
   └─ ...all var_* variables

Step 2: Load APP-SPECIFIC DEFAULTS
   ├─ Check if /usr/local/community-scripts/defaults/pihole.vars exists
   ├─ Load all var_* from that file
   └─ These override built-ins but NOT environment variables

Step 3: Load USER GLOBAL DEFAULTS
   ├─ Check if /usr/local/community-scripts/default.vars exists
   ├─ Load all var_* from that file
   └─ These override built-ins but NOT app-specific

Step 4: Use BUILT-IN DEFAULTS
   └─ Hardcoded in script (lowest priority)
```

### Precedence Examples

**Example 1: Environment Variable Wins**
```bash
# Shell environment has highest priority
$ export var_cpu=16
$ bash pihole-install.sh

# Result: Container gets 16 cores
# (ignores app defaults, user defaults, built-ins)
```

**Example 2: App Defaults Override User Defaults**
```bash
# User Defaults: var_cpu=4
# App Defaults: var_cpu=2
$ bash pihole-install.sh

# Result: Container gets 2 cores
# (app-specific setting takes precedence)
```

**Example 3: All Defaults Missing (Built-ins Used)**
```bash
# No environment variables set
# No app defaults file
# No user defaults file
$ bash pihole-install.sh

# Result: Uses built-in defaults
# (var_cpu might be 2 by default)
```

### Implementation in Code

```bash
# Typical pattern in build.func

base_settings() {
  # Priority 1: Environment variables (already set if export used)
  CT_TYPE=${var_unprivileged:-"1"}          # Use existing or default
  
  # Priority 2: Load app defaults (may override above)
  if [ -f "$(get_app_defaults_path)" ]; then
    load_vars_file "$(get_app_defaults_path)"
  fi
  
  # Priority 3: Load user defaults
  if [ -f "/usr/local/community-scripts/default.vars" ]; then
    load_vars_file "/usr/local/community-scripts/default.vars"
  fi
  
  # Priority 4: Apply built-in defaults (lowest)
  CORE_COUNT=${var_cpu:-"${APP_CPU_DEFAULT:-2}"}
  RAM_SIZE=${var_ram:-"${APP_RAM_DEFAULT:-1024}"}
  
  # Result: var_cpu has been set through precedence chain
}
```

---

## Data Flow Diagrams

### Installation Flow: Advanced Settings

```
┌──────────────┐
│  Start Script│
└──────┬───────┘
       │
       v
┌──────────────────────────────┐
│ Display Installation Mode    │
│ Menu (5 options)             │
└──────┬───────────────────────┘
       │ User selects "Advanced Settings"
       v
┌──────────────────────────────────┐
│ Call: base_settings()            │
│ (Apply built-in defaults)        │
└──────┬───────────────────────────┘
       │
       v
┌──────────────────────────────────┐
│ Call: advanced_settings()        │
│ (Show 19-step wizard)            │
│ - Ask CPU, RAM, Disk, Network... │
└──────┬───────────────────────────┘
       │
       v
┌──────────────────────────────────┐
│ Show Summary                     │
│ Review all chosen values         │
└──────┬───────────────────────────┘
       │ User confirms
       v
┌──────────────────────────────────┐
│ Create Container                 │
│ Using current variable values    │
└──────┬───────────────────────────┘
       │
       v
┌──────────────────────────────────┐
│ Installation Complete            │
└──────┬───────────────────────────┘
       │
       v
┌──────────────────────────────────────┐
│ Offer: Save as App Defaults?         │
│ (Save current settings)              │
└──────┬───────────────────────────────┘
       │
       ├─ YES → Save to defaults/<app>.vars
       │
       └─ NO  → Exit
```

### Variable Resolution Flow

```
CONTAINER CREATION STARTED
         │
         v
   ┌─────────────────────┐
   │ Check ENVIRONMENT   │
   │ for var_cpu, var_..│
   └──────┬──────────────┘
          │ Found? Use them (Priority 1)
          │ Not found? Continue...
          v
   ┌──────────────────────────┐
   │ Load App Defaults        │
   │ /defaults/<app>.vars     │
   └──────┬───────────────────┘
          │ File exists? Parse & load (Priority 2)
          │ Not found? Continue...
          v
   ┌──────────────────────────┐
   │ Load User Defaults       │
   │ /default.vars            │
   └──────┬───────────────────┘
          │ File exists? Parse & load (Priority 3)
          │ Not found? Continue...
          v
   ┌──────────────────────────┐
   │ Use Built-in Defaults    │
   │ (Hardcoded values)       │
   └──────┬───────────────────┘
          │
          v
   ┌──────────────────────────┐
   │ All Variables Resolved   │
   │ Ready for container      │
   │ creation                 │
   └──────────────────────────┘
```

---

## Security Model

### Threat Model

| Threat | Mitigation |
|--------|-----------|
| **Arbitrary Code Execution** | No `source` or `eval`; manual parsing only |
| **Variable Injection** | Whitelist of allowed variable names |
| **Command Substitution** | `_sanitize_value()` blocks `$()`, backticks, etc. |
| **Path Traversal** | Files locked to `/usr/local/community-scripts/` |
| **Permission Escalation** | Files created with restricted permissions |
| **Information Disclosure** | Sensitive variables not logged |

### Security Controls

#### 1. Input Validation

```bash
# Only specific variables allowed
if ! _is_whitelisted_key "$key"; then
  skip_this_variable
fi

# Values sanitized
if ! val="$(_sanitize_value "$value")"; then
  reject_entire_line
fi
```

#### 2. Safe File Parsing

```bash
# ❌ DANGEROUS (OLD)
source /path/to/config.conf
# Could execute: rm -rf / or any code

# ✅ SAFE (NEW)
load_vars_file "/path/to/config.conf"
# Only reads var_name=value pairs, no execution
```

#### 3. Whitelisting

```bash
# Only these variables can be configured
var_cpu, var_ram, var_disk, var_brg, ...
var_hostname, var_pw, var_ssh, ...

# NOT allowed:
var_malicious, var_hack, custom_var, ...
```

#### 4. Value Constraints

```bash
# No command injection patterns
if [[ "$value" =~ ($|`|;|&|<\() ]]; then
  reject_value
fi
```

---

## Implementation Details

### Module: `build.func`

**Load Order** (in actual scripts):
1. `#!/usr/bin/env bash` - Shebang
2. `source /dev/stdin <<<$(curl ... api.func)` - API functions
3. `source /dev/stdin <<<$(curl ... build.func)` - Build functions
4. `variables()` - Initialize variables
5. `check_root()` - Security check
6. `install_script()` - Main flow

**Key Sections**:

```bash
# Section 1: Initialization & Variables
- variables()
- NSAPP, var_install, INTEGER pattern, etc.

# Section 2: Storage Management
- storage_selector()
- ensure_storage_selection_for_vars_file()

# Section 3: Base Settings
- base_settings()          # Apply defaults to all var_*
- echo_default()           # Display current settings

# Section 4: Variable Loading
- load_vars_file()         # Safe parsing
- _is_whitelisted_key()    # Validation
- _sanitize_value()        # Threat mitigation

# Section 5: Defaults Management
- default_var_settings()   # Load user defaults
- get_app_defaults_path()  # Get app defaults path
- maybe_offer_save_app_defaults()  # Save option

# Section 6: Installation Flow
- install_script()         # Main entry point
- advanced_settings()      # 19-step wizard
```

### Regex Patterns Used

| Pattern | Purpose | Example Match |
|---------|---------|---|
| `^[0-9]+([.][0-9]+)?$` | Integer validation | `4`, `192.168` |
| `^var_[a-z_]+$` | Variable name | `var_cpu`, `var_ssh` |
| `*'$('*` | Command substitution | `$(whoami)` |
| `*\`*` | Backtick substitution | `` `cat /etc/passwd` `` |

---

## Appendix: Migration Reference

### Old Pattern (Deprecated)

```bash
# ❌ OLD: config-file.func
source config-file.conf          # Executes arbitrary code
if [ "$USE_DEFAULTS" = "yes" ]; then
  apply_settings_directly
fi
```

### New Pattern (Current)

```bash
# ✅ NEW: load_vars_file()
if load_vars_file "$(get_app_defaults_path)"; then
  echo "Settings loaded securely"
fi
```

### Function Mapping

| Old | New | Location |
|-----|-----|----------|
| `read_config()` | `load_vars_file()` | build.func |
| `write_config()` | `_build_current_app_vars_tmp()` | build.func |
| None | `maybe_offer_save_app_defaults()` | build.func |
| None | `get_app_defaults_path()` | build.func |

---

**End of Technical Reference**
