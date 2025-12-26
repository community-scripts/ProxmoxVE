# build.func Execution Flows

## Overview

This document details the execution flows for different installation modes and scenarios in `build.func`, including variable precedence, decision trees, and workflow patterns.

## Installation Modes

### 1. Default Install Flow

**Purpose**: Uses built-in defaults with minimal user interaction
**Use Case**: Quick container creation with standard settings

```
Default Install Flow:
├── start()
│   ├── Detect execution context
│   ├── Capture hard environment variables
│   └── Set CT_TYPE="install"
├── install_script()
│   ├── Display installation mode menu
│   ├── User selects "Default Install"
│   └── Proceed with defaults
├── variables()
│   ├── base_settings()  # Set built-in defaults
│   ├── Load app.vars (if exists)
│   ├── Load default.vars (if exists)
│   └── Apply variable precedence
├── build_container()
│   ├── validate_settings()
│   ├── check_conflicts()
│   └── create_lxc_container()
└── default_var_settings()
    └── Offer to save as defaults
```

**Key Characteristics**:
- Minimal user prompts
- Uses built-in defaults
- Fast execution
- Suitable for standard deployments

### 2. Advanced Install Flow

**Purpose**: Full interactive configuration via whiptail menus
**Use Case**: Custom container configuration with full control

```
Advanced Install Flow:
├── start()
│   ├── Detect execution context
│   ├── Capture hard environment variables
│   └── Set CT_TYPE="install"
├── install_script()
│   ├── Display installation mode menu
│   ├── User selects "Advanced Install"
│   └── Proceed with advanced configuration
├── variables()
│   ├── base_settings()  # Set built-in defaults
│   ├── Load app.vars (if exists)
│   ├── Load default.vars (if exists)
│   └── Apply variable precedence
├── advanced_settings()
│   ├── OS Selection Menu
│   ├── Resource Configuration Menu
│   ├── Network Configuration Menu
│   ├── select_storage()
│   │   ├── resolve_storage_preselect()
│   │   └── choose_and_set_storage_for_file()
│   ├── GPU Configuration Menu
│   │   └── detect_gpu_devices()
│   └── Feature Flags Menu
├── build_container()
│   ├── validate_settings()
│   ├── check_conflicts()
│   └── create_lxc_container()
└── default_var_settings()
    └── Offer to save as defaults
```

**Key Characteristics**:
- Full interactive configuration
- Whiptail menus for all options
- Complete control over settings
- Suitable for custom deployments

### 3. My Defaults Flow

**Purpose**: Loads settings from global default.vars file
**Use Case**: Using previously saved global defaults

```
My Defaults Flow:
├── start()
│   ├── Detect execution context
│   ├── Capture hard environment variables
│   └── Set CT_TYPE="install"
├── install_script()
│   ├── Display installation mode menu
│   ├── User selects "My Defaults"
│   └── Proceed with loaded defaults
├── variables()
│   ├── base_settings()  # Set built-in defaults
│   ├── Load app.vars (if exists)
│   ├── Load default.vars  # Load global defaults
│   └── Apply variable precedence
├── build_container()
│   ├── validate_settings()
│   ├── check_conflicts()
│   └── create_lxc_container()
└── default_var_settings()
    └── Offer to save as defaults
```

**Key Characteristics**:
- Uses global default.vars file
- Minimal user interaction
- Consistent with previous settings
- Suitable for repeated deployments

### 4. App Defaults Flow

**Purpose**: Loads settings from app-specific .vars file
**Use Case**: Using previously saved app-specific defaults

```
App Defaults Flow:
├── start()
│   ├── Detect execution context
│   ├── Capture hard environment variables
│   └── Set CT_TYPE="install"
├── install_script()
│   ├── Display installation mode menu
│   ├── User selects "App Defaults"
│   └── Proceed with app-specific defaults
├── variables()
│   ├── base_settings()  # Set built-in defaults
│   ├── Load app.vars  # Load app-specific defaults
│   ├── Load default.vars (if exists)
│   └── Apply variable precedence
├── build_container()
│   ├── validate_settings()
│   ├── check_conflicts()
│   └── create_lxc_container()
└── default_var_settings()
    └── Offer to save as defaults
```

**Key Characteristics**:
- Uses app-specific .vars file
- Minimal user interaction
- App-optimized settings
- Suitable for app-specific deployments

## Variable Precedence Chain

### Precedence Order (Highest to Lowest)

1. **Hard Environment Variables**: Set before script execution
2. **App-specific .vars file**: `/usr/local/community-scripts/defaults/<app>.vars`
3. **Global default.vars file**: `/usr/local/community-scripts/default.vars`
4. **Built-in defaults**: Set in `base_settings()` function

### Variable Resolution Process

```
Variable Resolution:
├── Capture hard environment variables at start()
├── Load built-in defaults in base_settings()
├── Load global default.vars (if exists)
├── Load app-specific .vars (if exists)
└── Apply precedence chain
    ├── Hard env vars override all
    ├── App.vars override default.vars and built-ins
    ├── Default.vars override built-ins
    └── Built-ins are fallback defaults
```

## Storage Selection Logic

### Storage Resolution Flow

```
Storage Selection:
├── Check if storage is preselected
│   ├── var_template_storage set? → Validate and use
│   └── var_container_storage set? → Validate and use
├── Count available storage options
│   ├── Only 1 option → Auto-select
│   └── Multiple options → Prompt user
├── User selection via whiptail
│   ├── Template storage selection
│   └── Container storage selection
└── Validate selected storage
    ├── Check availability
    ├── Check content type support
    └── Proceed with selection
```

### Storage Validation

```
Storage Validation:
├── Check storage exists
├── Check storage is online
├── Check content type support
│   ├── Template storage: vztmpl support
│   └── Container storage: rootdir support
├── Check available space
└── Validate permissions
```

## GPU Passthrough Flow

### GPU Detection and Configuration

```
GPU Passthrough Flow:
├── detect_gpu_devices()
│   ├── Scan for Intel GPUs
│   │   ├── Check i915 driver
│   │   └── Detect devices
│   ├── Scan for AMD GPUs
│   │   ├── Check AMDGPU driver
│   │   └── Detect devices
│   └── Scan for NVIDIA GPUs
│       ├── Check NVIDIA driver
│       ├── Detect devices
│       └── Check CUDA support
├── Check GPU passthrough eligibility
│   ├── Is app in GPU_APPS list?
│   ├── Is container privileged?
│   └── Proceed if eligible
├── GPU selection logic
│   ├── Single GPU type → Auto-select
│   └── Multiple GPU types → Prompt user
├── configure_gpu_passthrough()
│   ├── Add GPU device entries
│   ├── Configure permissions
│   └── Update container config
└── fix_gpu_gids()
    ├── Update GPU group IDs
    └── Configure access permissions
```

### GPU Eligibility Check

```
GPU Eligibility:
├── Check app support
│   ├── Is APP in GPU_APPS list?
│   └── Proceed if supported
├── Check container privileges
│   ├── Is ENABLE_PRIVILEGED="true"?
│   └── Proceed if privileged
└── Check hardware availability
    ├── Are GPUs detected?
    └── Proceed if available
```

## Network Configuration Flow

### Network Setup Process

```
Network Configuration:
├── Basic network settings
│   ├── var_net (network interface)
│   ├── var_bridge (bridge interface)
│   └── var_gateway (gateway IP)
├── IP configuration
│   ├── var_ip (IPv4 address)
│   ├── var_ipv6 (IPv6 address)
│   └── IPV6_METHOD (IPv6 method)
├── Advanced network settings
│   ├── var_vlan (VLAN ID)
│   ├── var_mtu (MTU size)
│   └── var_mac (MAC address)
└── Network validation
    ├── Check IP format
    ├── Check gateway reachability
    └── Validate network configuration
```

## Container Creation Flow

### LXC Container Creation Process

```
Container Creation:
├── create_lxc_container()
│   ├── Create basic container
│   ├── Configure network
│   ├── Set up storage
│   ├── Configure features
│   ├── Set resource limits
│   ├── Configure startup
│   └── Start container
├── Post-creation configuration
│   ├── Wait for network
│   ├── Configure GPU (if enabled)
│   ├── Set up SSH keys
│   └── Run post-install scripts
└── Finalization
    ├── Display container info
    ├── Show access details
    └── Provide next steps
```

## Error Handling Flows

### Validation Error Flow

```
Validation Error Flow:
├── validate_settings()
│   ├── Check configuration validity
│   └── Return error if invalid
├── check_conflicts()
│   ├── Check for conflicts
│   └── Return error if conflicts found
├── Error handling
│   ├── Display error message
│   ├── cleanup_on_error()
│   └── Exit with error code
└── User notification
    ├── Show error details
    └── Suggest fixes
```

### Storage Error Flow

```
Storage Error Flow:
├── Storage selection fails
├── Retry storage selection
│   ├── Show available options
│   └── Allow user to retry
├── Storage validation fails
│   ├── Show validation errors
│   └── Allow user to fix
└── Fallback to default storage
    ├── Use fallback storage
    └── Continue with creation
```

### GPU Error Flow

```
GPU Error Flow:
├── GPU detection fails
├── Fall back to no GPU
│   ├── Disable GPU passthrough
│   └── Continue without GPU
├── GPU configuration fails
│   ├── Show configuration errors
│   └── Allow user to retry
└── GPU permission errors
    ├── Fix GPU permissions
    └── Retry configuration
```

## Integration Flows

### With Install Scripts

```
Install Script Integration:
├── build.func creates container
├── Container starts successfully
├── Install script execution
│   ├── Download and install app
│   ├── Configure app settings
│   └── Set up services
└── Post-installation configuration
    ├── Verify installation
    ├── Configure access
    └── Display completion info
```

### With Proxmox API

```
Proxmox API Integration:
├── API authentication
├── Container creation via API
├── Configuration updates via API
├── Status monitoring via API
└── Error handling via API
```

## Performance Considerations

### Execution Time Optimization

```
Performance Optimization:
├── Parallel operations where possible
├── Minimal user interaction in default mode
├── Efficient storage selection
├── Optimized GPU detection
└── Streamlined validation
```

### Resource Usage

```
Resource Usage:
├── Minimal memory footprint
├── Efficient disk usage
├── Optimized network usage
└── Minimal CPU overhead
```
