# Misc Documentation

This directory contains comprehensive documentation for all function libraries and components of the Proxmox Community Scripts project. Each section is organized as a dedicated subdirectory with detailed references, examples, and integration guides.

---

## 🏗️ **Core Function Libraries**

### 📁 [build.func/](./build.func/)
**Core LXC Container Orchestration** - Main orchestrator for Proxmox LXC container creation

**Contents:**
- BUILD_FUNC_FLOWCHART.md - Visual execution flows and decision trees
- BUILD_FUNC_ARCHITECTURE.md - System architecture and design
- BUILD_FUNC_ENVIRONMENT_VARIABLES.md - Complete environment variable reference
- BUILD_FUNC_FUNCTIONS_REFERENCE.md - Alphabetical function reference
- BUILD_FUNC_EXECUTION_FLOWS.md - Detailed execution flows
- BUILD_FUNC_USAGE_EXAMPLES.md - Practical usage examples
- README.md - Overview and quick reference

**Key Functions**: `variables()`, `start()`, `build_container()`, `build_defaults()`, `advanced_settings()`

---

### 📁 [core.func/](./core.func/)
**System Utilities & Foundation** - Essential utility functions and system checks

**Contents:**
- CORE_FLOWCHART.md - Visual execution flows
- CORE_FUNCTIONS_REFERENCE.md - Complete function reference
- CORE_INTEGRATION.md - Integration points
- CORE_USAGE_EXAMPLES.md - Practical examples
- README.md - Overview and quick reference

**Key Functions**: `color()`, `msg_info()`, `msg_ok()`, `msg_error()`, `root_check()`, `pve_check()`, `parse_dev_mode()`

---

### 📁 [error_handler.func/](./error_handler.func/)
**Error Handling & Signal Management** - Comprehensive error handling and signal trapping

**Contents:**
- ERROR_HANDLER_FLOWCHART.md - Visual error handling flows
- ERROR_HANDLER_FUNCTIONS_REFERENCE.md - Function reference
- ERROR_HANDLER_INTEGRATION.md - Integration with other components
- ERROR_HANDLER_USAGE_EXAMPLES.md - Practical examples
- README.md - Overview and quick reference

**Key Functions**: `catch_errors()`, `error_handler()`, `explain_exit_code()`, `signal_handler()`

---

### 📁 [api.func/](./api.func/)
**Proxmox API Integration** - API communication and diagnostic reporting

**Contents:**
- API_FLOWCHART.md - API communication flows
- API_FUNCTIONS_REFERENCE.md - Function reference
- API_INTEGRATION.md - Integration points
- API_USAGE_EXAMPLES.md - Practical examples
- README.md - Overview and quick reference

**Key Functions**: `post_to_api()`, `post_update_to_api()`, `get_error_description()`

---

## 📦 **Installation & Setup Function Libraries**

### 📁 [install.func/](./install.func/)
**Container Installation Workflow** - Installation orchestration for container-internal setup

**Contents:**
- INSTALL_FUNC_FLOWCHART.md - Installation workflow diagrams
- INSTALL_FUNC_FUNCTIONS_REFERENCE.md - Complete function reference
- INSTALL_FUNC_INTEGRATION.md - Integration with build and tools
- INSTALL_FUNC_USAGE_EXAMPLES.md - Practical examples
- README.md - Overview and quick reference

**Key Functions**: `setting_up_container()`, `network_check()`, `update_os()`, `motd_ssh()`, `cleanup_lxc()`

---

### 📁 [tools.func/](./tools.func/)
**Package & Tool Installation** - Robust package management and 30+ tool installation functions

**Contents:**
- TOOLS_FUNC_FLOWCHART.md - Package management flows
- TOOLS_FUNC_FUNCTIONS_REFERENCE.md - 30+ function reference
- TOOLS_FUNC_INTEGRATION.md - Integration with install workflows
- TOOLS_FUNC_USAGE_EXAMPLES.md - Practical examples
- TOOLS_FUNC_ENVIRONMENT_VARIABLES.md - Configuration reference
- README.md - Overview and quick reference

**Key Functions**: `setup_nodejs()`, `setup_php()`, `setup_mariadb()`, `setup_docker()`, `setup_deb822_repo()`, `pkg_install()`, `pkg_update()`

---

### 📁 [alpine-install.func/](./alpine-install.func/)
**Alpine Container Setup** - Alpine Linux-specific installation functions

**Contents:**
- ALPINE_INSTALL_FUNC_FLOWCHART.md - Alpine setup flows
- ALPINE_INSTALL_FUNC_FUNCTIONS_REFERENCE.md - Function reference
- ALPINE_INSTALL_FUNC_INTEGRATION.md - Integration points
- ALPINE_INSTALL_FUNC_USAGE_EXAMPLES.md - Practical examples
- README.md - Overview and quick reference

**Key Functions**: `update_os()` (apk version), `verb_ip6()`, `motd_ssh()` (Alpine), `customize()`

---

### 📁 [alpine-tools.func/](./alpine-tools.func/)
**Alpine Tool Installation** - Alpine-specific package and tool installation

**Contents:**
- ALPINE_TOOLS_FUNC_FLOWCHART.md - Alpine package flows
- ALPINE_TOOLS_FUNC_FUNCTIONS_REFERENCE.md - Function reference
- ALPINE_TOOLS_FUNC_INTEGRATION.md - Integration with Alpine workflows
- ALPINE_TOOLS_FUNC_USAGE_EXAMPLES.md - Practical examples
- README.md - Overview and quick reference

**Key Functions**: `apk_add()`, `apk_update()`, `apk_del()`, `add_community_repo()`, Alpine tool setup functions

---

### 📁 [cloud-init.func/](./cloud-init.func/)
**VM Cloud-Init Configuration** - Cloud-init and VM provisioning functions

**Contents:**
- CLOUD_INIT_FUNC_FLOWCHART.md - Cloud-init flows
- CLOUD_INIT_FUNC_FUNCTIONS_REFERENCE.md - Function reference
- CLOUD_INIT_FUNC_INTEGRATION.md - Integration points
- CLOUD_INIT_FUNC_USAGE_EXAMPLES.md - Practical examples
- README.md - Overview and quick reference

**Key Functions**: `generate_cloud_init()`, `generate_user_data()`, `setup_ssh_keys()`, `setup_static_ip()`

---

## 🔗 **Function Library Relationships**

```
┌─────────────────────────────────────────────┐
│       Container Creation Flow               │
├─────────────────────────────────────────────┤
│                                             │
│  ct/AppName.sh                              │
│      ↓ (sources)                            │
│  build.func                                 │
│      ├─ variables()                         │
│      ├─ build_container()                   │
│      └─ advanced_settings()                 │
│      ↓ (calls pct create with)              │
│  install/appname-install.sh                 │
│      ↓ (sources)                            │
│      ├─ core.func      (colors, messaging)  │
│      ├─ error_handler.func (error trapping) │
│      ├─ install.func   (setup/network)      │
│      └─ tools.func     (packages/tools)     │
│                                             │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│       Alpine Container Flow                 │
├─────────────────────────────────────────────┤
│                                             │
│  install/appname-install.sh (Alpine)        │
│      ↓ (sources)                            │
│      ├─ core.func              (colors)     │
│      ├─ error_handler.func     (errors)     │
│      ├─ alpine-install.func    (apk setup)  │
│      └─ alpine-tools.func      (apk tools)  │
│                                             │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│       VM Provisioning Flow                  │
├─────────────────────────────────────────────┤
│                                             │
│  vm/OsName-vm.sh                            │
│      ↓ (uses)                               │
│  cloud-init.func                            │
│      ├─ generate_cloud_init()               │
│      ├─ setup_ssh_keys()                    │
│      └─ configure_network()                 │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 📊 **Documentation Quick Stats**

| Library | Files | Functions | Status |
|---------|:---:|:---:|:---:|
| build.func | 7 | 50+ | ✅ Complete |
| core.func | 5 | 20+ | ✅ Complete |
| error_handler.func | 5 | 10+ | ✅ Complete |
| api.func | 5 | 5+ | ✅ Complete |
| install.func | 5 | 8+ | ✅ Complete |
| tools.func | 6 | 30+ | ✅ Complete |
| alpine-install.func | 5 | 6+ | ✅ Complete |
| alpine-tools.func | 5 | 15+ | ✅ Complete |
| cloud-init.func | 5 | 12+ | ✅ Complete |

**Total**: 9 function libraries, 48 documentation files, 150+ functions

---

## 🚀 **Getting Started**

### For Container Creation Scripts
Start with: **[build.func/](./build.func/)** → **[tools.func/](./tools.func/)** → **[install.func/](./install.func/)**

### For Alpine Containers
Start with: **[alpine-install.func/](./alpine-install.func/)** → **[alpine-tools.func/](./alpine-tools.func/)**

### For VM Provisioning
Start with: **[cloud-init.func/](./cloud-init.func/)**

### For Troubleshooting
Start with: **[error_handler.func/](./error_handler.func/)** → **[EXIT_CODES.md](../EXIT_CODES.md)**

---

## 📚 **Related Top-Level Documentation**

- **[CONTRIBUTION_GUIDE.md](../CONTRIBUTION_GUIDE.md)** - How to contribute to ProxmoxVE
- **[UPDATED_APP-ct.md](../UPDATED_APP-ct.md)** - Container script guide
- **[UPDATED_APP-install.md](../UPDATED_APP-install.md)** - Installation script guide
- **[DEFAULTS_SYSTEM_GUIDE.md](../DEFAULTS_SYSTEM_GUIDE.md)** - Configuration system
- **[TECHNICAL_REFERENCE.md](../TECHNICAL_REFERENCE.md)** - Architecture reference
- **[EXIT_CODES.md](../EXIT_CODES.md)** - Complete exit code reference
- **[DEV_MODE.md](../DEV_MODE.md)** - Development debugging modes
- **[CHANGELOG_MISC.md](../CHANGELOG_MISC.md)** - Change history

---

## 🔄 **Standardized Documentation Structure**

Each function library follows the same documentation pattern:

```
function-library/
├── README.md                          # Quick reference & overview
├── FUNCTION_LIBRARY_FLOWCHART.md      # Visual execution flows
├── FUNCTION_LIBRARY_FUNCTIONS_REFERENCE.md  # Alphabetical reference
├── FUNCTION_LIBRARY_INTEGRATION.md    # Integration points
├── FUNCTION_LIBRARY_USAGE_EXAMPLES.md # Practical examples
└── [FUNCTION_LIBRARY_ENVIRONMENT_VARIABLES.md]  # (if applicable)
```

**Advantages**:
- ✅ Consistent navigation across all libraries
- ✅ Quick reference sections in each README
- ✅ Visual flowcharts for understanding
- ✅ Complete function references
- ✅ Real-world usage examples
- ✅ Integration guides for connecting libraries

---

## 📝 **Documentation Standards**

All documentation follows these standards:

1. **README.md** - Quick overview, key features, quick reference
2. **FLOWCHART.md** - ASCII flowcharts and visual diagrams
3. **FUNCTIONS_REFERENCE.md** - Every function with full details
4. **INTEGRATION.md** - How this library connects to others
5. **USAGE_EXAMPLES.md** - Copy-paste ready examples
6. **ENVIRONMENT_VARIABLES.md** - (if applicable) Configuration reference

---

## ✅ **Last Updated**: December 2025
**Maintainers**: community-scripts team
**License**: MIT
**Status**: All 9 libraries fully documented and standardized

---

*This directory contains specialized documentation for specific components of the Proxmox Community Scripts project.*
