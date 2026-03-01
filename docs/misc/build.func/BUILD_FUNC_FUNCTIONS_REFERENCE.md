# build.func Functions Reference

## Overview

This document provides a comprehensive reference of all functions in `build.func`, organized alphabetically with detailed descriptions, parameters, and usage information.

## Function Categories

### Initialization Functions

#### `start()`

**Purpose**: Main entry point when build.func is sourced or executed
**Parameters**: None
**Returns**: None
**Side Effects**:

- Detects execution context (Proxmox host vs container)
- Captures hard environment variables
- Sets CT_TYPE based on context
- Routes to appropriate workflow (install_script or update_script)
  **Dependencies**: None
  **Environment Variables Used**: `CT_TYPE`, `APP`, `CTID`

#### `variables()`

**Purpose**: Load and resolve all configuration variables using precedence chain
**Parameters**: None
**Returns**: None
**Side Effects**:

- Loads app-specific .vars file
- Loads global default.vars file
- Applies variable precedence chain
- Sets all configuration variables
  **Dependencies**: `base_settings()`
  **Environment Variables Used**: All configuration variables

#### `base_settings()`

**Purpose**: Set built-in default values for all configuration variables
**Parameters**: None
**Returns**: None
**Side Effects**: Sets default values for all variables
**Dependencies**: None
**Environment Variables Used**: All configuration variables

### UI and Menu Functions

#### `install_script()`

**Purpose**: Main installation workflow coordinator
**Parameters**: None
**Returns**: None
**Side Effects**:

- Displays installation mode selection menu
- Coordinates the entire installation process
- Handles user interaction and validation
  **Dependencies**: `variables()`, `build_container()`, `default_var_settings()`
  **Environment Variables Used**: `APP`, `CTID`, `var_hostname`

#### `advanced_settings()`

**Purpose**: Provide advanced configuration options via whiptail menus
**Parameters**: None
**Returns**: None
**Side Effects**:

- Displays whiptail menus for configuration
- Updates configuration variables based on user input
- Validates user selections
  **Dependencies**: `select_storage()`, `detect_gpu_devices()`
  **Environment Variables Used**: All configuration variables

#### `settings_menu()`

**Purpose**: Display and handle settings configuration menu
**Parameters**: None
**Returns**: None
**Side Effects**: Updates configuration variables
**Dependencies**: `advanced_settings()`
**Environment Variables Used**: All configuration variables

### Storage Functions

#### `select_storage()`

**Purpose**: Handle storage selection for templates and containers
**Parameters**: None
**Returns**: None
**Side Effects**:

- Resolves storage preselection
- Prompts user for storage selection if needed
- Validates storage availability
- Sets var_template_storage and var_container_storage
  **Dependencies**: `resolve_storage_preselect()`, `choose_and_set_storage_for_file()`
  **Environment Variables Used**: `var_template_storage`, `var_container_storage`, `TEMPLATE_STORAGE`, `CONTAINER_STORAGE`

#### `resolve_storage_preselect()`

**Purpose**: Resolve preselected storage options
**Parameters**:

- `storage_type`: Type of storage (template or container)
  **Returns**: Storage name if valid, empty if invalid
  **Side Effects**: Validates storage availability
  **Dependencies**: None
  **Environment Variables Used**: `var_template_storage`, `var_container_storage`

#### `choose_and_set_storage_for_file()`

**Purpose**: Interactive storage selection via whiptail
**Parameters**:

- `storage_type`: Type of storage (template or container)
- `content_type`: Content type (vztmpl or rootdir)
  **Returns**: None
  **Side Effects**:
- Displays whiptail menu
- Updates storage variables
- Validates selection
  **Dependencies**: None
  **Environment Variables Used**: `var_template_storage`, `var_container_storage`

### Container Creation Functions

#### `build_container()`

**Purpose**: Validate settings and prepare container creation
**Parameters**: None
**Returns**: None
**Side Effects**:

- Validates all configuration
- Checks for conflicts
- Prepares container configuration
- Calls create_lxc_container()
  **Dependencies**: `create_lxc_container()`
  **Environment Variables Used**: All configuration variables

#### `create_lxc_container()`

**Purpose**: Create the actual LXC container
**Parameters**: None
**Returns**: None
**Side Effects**:

- Creates LXC container with basic configuration
- Configures network settings
- Sets up storage and mount points
- Configures features (FUSE, TUN, etc.)
- Sets resource limits
- Configures startup options
- Starts container
  **Dependencies**: `configure_gpu_passthrough()`, `fix_gpu_gids()`
  **Environment Variables Used**: All configuration variables

### GPU and Hardware Functions

#### `detect_gpu_devices()`

**Purpose**: Detect available GPU hardware on the system
**Parameters**: None
**Returns**: None
**Side Effects**:

- Scans for Intel, AMD, and NVIDIA GPUs
- Updates var_gpu_type and var_gpu_devices
- Determines GPU capabilities
  **Dependencies**: None
  **Environment Variables Used**: `var_gpu_type`, `var_gpu_devices`, `GPU_APPS`

#### `configure_gpu_passthrough()`

**Purpose**: Configure GPU passthrough for the container
**Parameters**: None
**Returns**: None
**Side Effects**:

- Adds GPU device entries to container config
- Configures proper device permissions
- Sets up device mapping
- Updates /etc/pve/lxc/<ctid>.conf
  **Dependencies**: `detect_gpu_devices()`
  **Environment Variables Used**: `var_gpu`, `var_gpu_type`, `var_gpu_devices`, `CTID`

#### `fix_gpu_gids()`

**Purpose**: Fix GPU group IDs after container creation
**Parameters**: None
**Returns**: None
**Side Effects**:

- Updates GPU group IDs in container
- Ensures proper GPU access permissions
- Configures video and render groups
  **Dependencies**: `configure_gpu_passthrough()`
  **Environment Variables Used**: `CTID`, `var_gpu_type`

### SSH Configuration Functions

#### `configure_ssh_settings()`

**Purpose**: Interactive SSH key and access configuration wizard
**Parameters**:

- `step_info` (optional): Step indicator string (e.g., "Step 17/19") for consistent dialog headers
  **Returns**: None
  **Side Effects**:
- Creates temporary file for SSH keys
- Discovers and presents available SSH keys from host
- Allows manual key entry or folder/glob scanning
- Sets `SSH` variable to "yes" or "no" based on user selection
- Sets `SSH_AUTHORIZED_KEY` if manual key provided
- Populates `SSH_KEYS_FILE` with selected keys
  **Dependencies**: `ssh_discover_default_files()`, `ssh_build_choices_from_files()`
  **Environment Variables Used**: `SSH`, `SSH_AUTHORIZED_KEY`, `SSH_KEYS_FILE`

**SSH Key Source Options**:

1. `found` - Select from auto-detected host keys
2. `manual` - Paste a single public key
3. `folder` - Scan custom folder or glob pattern
4. `none` - No SSH keys

**Note**: The "Enable root SSH access?" dialog is always shown, regardless of whether SSH keys or password are configured. This ensures users can always enable SSH access even with automatic login.

#### `ssh_discover_default_files()`

**Purpose**: Discover SSH public key files on the host system
**Parameters**: None
**Returns**: Array of discovered key file paths
**Side Effects**: Scans common SSH key locations
**Dependencies**: None
**Environment Variables Used**: `var_ssh_import_glob`

#### `ssh_build_choices_from_files()`

**Purpose**: Build whiptail checklist choices from SSH key files
**Parameters**:

- Array of file paths to process
  **Returns**: None
  **Side Effects**:
- Sets `CHOICES` array for whiptail checklist
- Sets `COUNT` variable with number of keys found
- Creates `MAPFILE` for key tag to content mapping
  **Dependencies**: None
  **Environment Variables Used**: `CHOICES`, `COUNT`, `MAPFILE`

### Settings Persistence Functions

#### `default_var_settings()`

**Purpose**: Offer to save current settings as defaults
**Parameters**: None
**Returns**: None
**Side Effects**:

- Prompts user to save settings
- Saves to default.vars file
- Saves to app-specific .vars file
  **Dependencies**: `maybe_offer_save_app_defaults()`
  **Environment Variables Used**: All configuration variables

#### `maybe_offer_save_app_defaults()`

**Purpose**: Offer to save app-specific defaults
**Parameters**: None
**Returns**: None
**Side Effects**:

- Prompts user to save app-specific settings
- Saves to app.vars file
- Updates app-specific configuration
  **Dependencies**: None
  **Environment Variables Used**: `APP`, `SAVE_APP_DEFAULTS`

### Utility Functions

#### `validate_settings()`

**Purpose**: Validate all configuration settings
**Parameters**: None
**Returns**: 0 if valid, 1 if invalid
**Side Effects**:

- Checks for configuration conflicts
- Validates resource limits
- Validates network configuration
- Validates storage configuration
  **Dependencies**: None
  **Environment Variables Used**: All configuration variables

#### `check_conflicts()`

**Purpose**: Check for configuration conflicts
**Parameters**: None
**Returns**: 0 if no conflicts, 1 if conflicts found
**Side Effects**:

- Checks for conflicting settings
- Validates resource allocation
- Checks network configuration
  **Dependencies**: None
  **Environment Variables Used**: All configuration variables

#### `cleanup_on_error()`

**Purpose**: Clean up resources on error
**Parameters**: None
**Returns**: None
**Side Effects**:

- Removes partially created containers
- Cleans up temporary files
- Resets configuration
  **Dependencies**: None
  **Environment Variables Used**: `CTID`

## Function Call Flow

### Main Installation Flow

```
start()
├── variables()
│   ├── base_settings()
│   ├── Load app.vars
│   └── Load default.vars
├── install_script()
│   ├── advanced_settings()
│   │   ├── select_storage()
│   │   │   ├── resolve_storage_preselect()
│   │   │   └── choose_and_set_storage_for_file()
│   │   └── detect_gpu_devices()
│   ├── build_container()
│   │   ├── validate_settings()
│   │   ├── check_conflicts()
│   │   └── create_lxc_container()
│   │       ├── configure_gpu_passthrough()
│   │       └── fix_gpu_gids()
│   └── default_var_settings()
│       └── maybe_offer_save_app_defaults()
```

### Error Handling Flow

```
Error Detection
├── validate_settings()
│   └── check_conflicts()
├── Error Handling
│   └── cleanup_on_error()
└── Exit with error code
```

## Function Dependencies

### Core Dependencies

- `start()` → `install_script()` → `build_container()` → `create_lxc_container()`
- `variables()` → `base_settings()`
- `advanced_settings()` → `select_storage()` → `detect_gpu_devices()`

### Storage Dependencies

- `select_storage()` → `resolve_storage_preselect()`
- `select_storage()` → `choose_and_set_storage_for_file()`

### GPU Dependencies

- `configure_gpu_passthrough()` → `detect_gpu_devices()`
- `fix_gpu_gids()` → `configure_gpu_passthrough()`

### Settings Dependencies

- `default_var_settings()` → `maybe_offer_save_app_defaults()`

## Function Usage Examples

### Basic Container Creation

```bash
# Set required variables
export APP="plex"
export CTID="100"
export var_hostname="plex-server"

# Call main functions
start()  # Entry point
# → variables()  # Load configuration
# → install_script()  # Main workflow
# → build_container()  # Create container
# → create_lxc_container()  # Actual creation
```

### Advanced Configuration

```bash
# Set advanced variables
export var_os="debian"
export var_version="12"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"

# Call advanced functions
advanced_settings()  # Interactive configuration
# → select_storage()  # Storage selection
# → detect_gpu_devices()  # GPU detection
```

### GPU Passthrough

```bash
# Enable GPU passthrough
export GPU_APPS="plex"
export var_gpu="nvidia"

# Call GPU functions
detect_gpu_devices()  # Detect hardware
configure_gpu_passthrough()  # Configure passthrough
fix_gpu_gids()  # Fix permissions
```

### Settings Persistence

```bash
# Save settings as defaults
export SAVE_DEFAULTS="true"
export SAVE_APP_DEFAULTS="true"

# Call persistence functions
default_var_settings()  # Save global defaults
maybe_offer_save_app_defaults()  # Save app defaults
```

### Container Resource & ID Management

#### `validate_container_id()`
**Purpose**: Validates if a container ID is available for use.
**Parameters**: `ctid` (Integer)
**Returns**: `0` if available, `1` if already in use or invalid.
**Description**: Checks for existing config files in `/etc/pve/lxc/` or `/etc/pve/qemu-server/`, and verifies LVM logical volumes.

#### `get_valid_container_id()`
**Purpose**: Returns the next available, unused container ID.
**Parameters**: `suggested_id` (Optional)
**Returns**: A valid container ID string.
**Description**: If the suggested ID is taken, it increments until it finds an available one.

#### `maxkeys_check()`
**Purpose**: Ensures host kernel parameters support high numbers of keys (required for some apps).
**Parameters**: None
**Description**: Checks and optionally updates `kernel.keys.maxkeys` and `kernel.keys.maxbytes`.

#### `get_current_ip()`
**Purpose**: Retrieves the current IP address of the container.
**Parameters**: `ctid` (Integer)
**Returns**: IP address string.

#### `update_motd_ip()`
**Purpose**: Updates the Message of the Day (MOTD) file with the container's IP.
**Parameters**: None

## Function Error Handling

### Validation Functions

- `validate_settings()`: Returns 0 for valid, 1 for invalid
- `check_conflicts()`: Returns 0 for no conflicts, 1 for conflicts

### Error Recovery

- `cleanup_on_error()`: Cleans up on any error
- Error codes are propagated up the call stack
- Critical errors cause script termination

### Error Types

1. **Configuration Errors**: Invalid settings or conflicts
2. **Resource Errors**: Insufficient resources or conflicts
3. **Network Errors**: Invalid network configuration
4. **Storage Errors**: Storage not available or invalid
5. **GPU Errors**: GPU configuration failures
6. **Container Creation Errors**: LXC creation failures
