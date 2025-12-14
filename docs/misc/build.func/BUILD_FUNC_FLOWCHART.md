# build.func Execution Flowchart

## Main Execution Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                START()                                          │
│  Entry point when build.func is sourced or executed                            │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          Check Environment                                      │
│  • Detect if running on Proxmox host vs inside container                      │
│  • Capture hard environment variables                                          │
│  • Set CT_TYPE based on context                                               │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Determine Action                                        │
│  • If CT_TYPE="update" → update_script()                                       │
│  • If CT_TYPE="install" → install_script()                                    │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        INSTALL_SCRIPT()                                        │
│  Main container creation workflow                                              │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Installation Mode Selection                             │
│                                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │   Default       │  │   Advanced      │  │   My Defaults   │  │ App Defaults│ │
│  │   Install       │  │   Install       │  │                 │  │             │ │
│  │                 │  │                 │  │                 │  │             │ │
│  │ • Use built-in  │  │ • Full whiptail │  │ • Load from     │  │ • Load from │ │
│  │   defaults      │  │   menus         │  │   default.vars  │  │   app.vars  │ │
│  │ • Minimal       │  │ • Interactive   │  │ • Override      │  │ • App-      │ │
│  │   prompts       │  │   configuration │  │   built-ins     │  │   specific  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        VARIABLES()                                             │
│  • Load variable precedence chain:                                             │
│    1. Hard environment variables                                               │
│    2. App-specific .vars file                                                  │
│    3. Global default.vars file                                                 │
│    4. Built-in defaults in base_settings()                                    │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        BASE_SETTINGS()                                         │
│  • Set core container parameters                                               │
│  • Configure OS selection                                                      │
│  • Set resource defaults (CPU, RAM, Disk)                                      │
│  • Configure network defaults                                                  │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Storage Selection Logic                                 │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    SELECT_STORAGE()                                       │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐ │ │
│  │  │   Template      │    │   Container     │    │     Resolution          │ │ │
│  │  │   Storage       │    │   Storage       │    │     Logic               │ │ │
│  │  │                 │    │                 │    │                         │ │ │
│  │  │ • Check if      │    │ • Check if      │    │ 1. Only 1 storage      │ │ │
│  │  │   preselected   │    │   preselected   │    │    → Auto-select        │ │ │
│  │  │ • Validate      │    │ • Validate      │    │ 2. Preselected         │ │ │
│  │  │   availability  │    │   availability  │    │    → Validate & use    │ │ │
│  │  │ • Prompt if     │    │ • Prompt if     │    │ 3. Multiple options    │ │ │
│  │  │   needed        │    │   needed        │    │    → Prompt user        │ │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        BUILD_CONTAINER()                                       │
│  • Validate all settings                                                       │
│  • Check for conflicts                                                          │
│  • Prepare container configuration                                             │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        CREATE_LXC_CONTAINER()                                  │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                     Container Creation Process                             │ │
│  │                                                                           │ │
│  │  1. Create LXC container with basic configuration                         │ │
│  │  2. Configure network settings                                            │ │
│  │  3. Set up storage and mount points                                       │ │
│  │  4. Configure features (FUSE, TUN, etc.)                                  │ │
│  │  5. Set resource limits                                                   │ │
│  │  6. Configure startup options                                             │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        GPU Passthrough Decision Tree                           │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    DETECT_GPU_DEVICES()                                    │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐ │ │
│  │  │   Intel GPU     │    │   AMD GPU       │    │     NVIDIA GPU          │ │ │
│  │  │                 │    │                 │    │                         │ │ │
│  │  │ • Check i915    │    │ • Check AMDGPU  │    │ • Check NVIDIA         │ │ │
│  │  │   driver        │    │   driver        │    │   driver                │ │ │
│  │  │ • Detect        │    │ • Detect        │    │ • Detect devices        │ │ │
│  │  │   devices       │    │   devices       │    │ • Check CUDA support    │ │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    GPU Selection Logic                                     │ │
│  │                                                                           │ │
│  │  • Is app in GPU_APPS list? OR Is container privileged?                   │ │
│  │    └─ YES → Proceed with GPU configuration                                │ │
│  │    └─ NO → Skip GPU passthrough                                          │ │
│  │                                                                           │ │
│  │  • Single GPU type detected?                                              │ │
│  │    └─ YES → Auto-select and configure                                     │ │
│  │    └─ NO → Prompt user for selection                                      │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        CONFIGURE_GPU_PASSTHROUGH()                             │
│  • Add GPU device entries to /etc/pve/lxc/<ctid>.conf                         │
│  • Configure proper device permissions                                        │
│  • Set up device mapping                                                       │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Container Finalization                                  │
│  • Start container                                                             │
│  • Wait for network connectivity                                               │
│  • Fix GPU GIDs (if GPU passthrough enabled)                                  │
│  • Configure SSH keys (if enabled)                                            │
│  • Run post-installation scripts                                              │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Settings Persistence                                    │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    DEFAULT_VAR_SETTINGS()                                  │ │
│  │                                                                           │ │
│  │  • Offer to save current settings as defaults                             │ │
│  │  • Save to /usr/local/community-scripts/default.vars                     │ │
│  │  • Save to /usr/local/community-scripts/defaults/<app>.vars               │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              COMPLETION                                        │
│  • Display container information                                               │
│  • Show access details                                                         │
│  • Provide next steps                                                         │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Key Decision Points

### 1. Installation Mode Selection
- **Default**: Uses built-in defaults, minimal user interaction
- **Advanced**: Full interactive configuration via whiptail menus
- **My Defaults**: Loads settings from global default.vars file
- **App Defaults**: Loads settings from app-specific .vars file

### 2. Storage Selection Logic
```
Storage Selection Flow:
├── Check if storage is preselected via environment variables
│   ├── YES → Validate availability and use
│   └── NO → Continue to resolution logic
├── Count available storage options for content type
│   ├── Only 1 option → Auto-select
│   └── Multiple options → Prompt user via whiptail
└── Validate selected storage and proceed
```

### 3. GPU Passthrough Decision Tree
```
GPU Passthrough Flow:
├── Detect available GPU hardware
│   ├── Intel GPU detected
│   ├── AMD GPU detected
│   └── NVIDIA GPU detected
├── Check if GPU passthrough should be enabled
│   ├── App is in GPU_APPS list? → YES
│   ├── Container is privileged? → YES
│   └── Neither? → Skip GPU passthrough
├── Configure GPU passthrough
│   ├── Single GPU type → Auto-configure
│   └── Multiple GPU types → Prompt user
└── Fix GPU GIDs post-creation
```

### 4. Variable Precedence Chain
```
Variable Resolution Order:
1. Hard environment variables (captured at start)
2. App-specific .vars file (/usr/local/community-scripts/defaults/<app>.vars)
3. Global default.vars file (/usr/local/community-scripts/default.vars)
4. Built-in defaults in base_settings() function
```

## Error Handling Flow

```
Error Handling:
├── Validation errors → Display error message and exit
├── Storage errors → Retry storage selection
├── Network errors → Retry network configuration
├── GPU errors → Fall back to no GPU passthrough
└── Container creation errors → Cleanup and exit
```

## Integration Points

- **Core Functions**: Depends on core.func for basic utilities
- **Error Handling**: Uses error_handler.func for error management
- **API Functions**: Uses api.func for Proxmox API interactions
- **Tools**: Uses tools.func for additional utilities
- **Install Scripts**: Integrates with <app>-install.sh scripts
