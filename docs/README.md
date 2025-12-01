# 📚 ProxmoxVE Documentation

Complete guide to all ProxmoxVE documentation - quickly find what you need.

---

## 🎯 **Quick Navigation by Goal**

### 👤 **I want to...**

**Contribute a new application**
→ Start with: [contribution/README.md](contribution/README.md)
→ Then: [ct/DETAILED_GUIDE.md](ct/DETAILED_GUIDE.md) + [install/DETAILED_GUIDE.md](install/DETAILED_GUIDE.md)

**Understand the architecture**
→ Read: [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)
→ Then: [misc/README.md](misc/README.md)

**Debug a failed installation**
→ Check: [EXIT_CODES.md](EXIT_CODES.md)
→ Then: [DEV_MODE.md](DEV_MODE.md)
→ See also: [misc/error_handler.func/](misc/error_handler.func/)

**Configure system defaults**
→ Read: [DEFAULTS_SYSTEM_GUIDE.md](DEFAULTS_SYSTEM_GUIDE.md)

**Develop a function library**
→ Study: [misc/](misc/) documentation

---

## 👤 **Quick Start by Role**

### **I'm a...**

**New Contributor**
→ Start: [contribution/README.md](contribution/README.md)
→ Then: Choose your path below

**Container Creator**
→ Read: [ct/README.md](ct/README.md)
→ Deep Dive: [ct/DETAILED_GUIDE.md](ct/DETAILED_GUIDE.md)
→ Reference: [misc/build.func/](misc/build.func/)

**Installation Script Developer**
→ Read: [install/README.md](install/README.md)
→ Deep Dive: [install/DETAILED_GUIDE.md](install/DETAILED_GUIDE.md)
→ Reference: [misc/tools.func/](misc/tools.func/)

**VM Provisioner**
→ Read: [vm/README.md](vm/README.md)
→ Reference: [misc/cloud-init.func/](misc/cloud-init.func/)

**Tools Developer**
→ Read: [tools/README.md](tools/README.md)
→ Reference: [misc/build.func/](misc/build.func/)

**API Integrator**
→ Read: [api/README.md](api/README.md)
→ Reference: [misc/api.func/](misc/api.func/)

**System Operator**
→ Start: [EXIT_CODES.md](EXIT_CODES.md)
→ Then: [DEFAULTS_SYSTEM_GUIDE.md](DEFAULTS_SYSTEM_GUIDE.md)
→ Debug: [DEV_MODE.md](DEV_MODE.md)

**Architect**
→ Read: [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)
→ Deep Dive: [misc/README.md](misc/README.md)

---

## 📂 **Documentation Structure**

### Project-Mirrored Directories

Each major project directory has documentation:

```
ProxmoxVE/
├─ ct/                 ↔ docs/ct/ (README.md + DETAILED_GUIDE.md)
├─ install/           ↔ docs/install/ (README.md + DETAILED_GUIDE.md)
├─ vm/                ↔ docs/vm/ (README.md)
├─ tools/            ↔ docs/tools/ (README.md)
├─ api/              ↔ docs/api/ (README.md)
└─ misc/             ↔ docs/misc/ (9 function libraries)
```

### Core Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| [contribution/README.md](contribution/README.md) | How to contribute | Contributors |
| [ct/DETAILED_GUIDE.md](ct/DETAILED_GUIDE.md) | Create ct scripts | Container developers |
| [install/DETAILED_GUIDE.md](install/DETAILED_GUIDE.md) | Create install scripts | Installation developers |
| [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md) | Architecture deep-dive | Architects, advanced users |
| [DEFAULTS_SYSTEM_GUIDE.md](DEFAULTS_SYSTEM_GUIDE.md) | Configuration system | Operators, power users |
| [EXIT_CODES.md](EXIT_CODES.md) | Exit code reference | Troubleshooters |
| [DEV_MODE.md](DEV_MODE.md) | Debugging tools | Developers |

---

## 📂 **Directory Guide**

### [ct/](ct/) - Container Scripts
Documentation for `/ct` - Container creation scripts that run on the Proxmox host.

**Includes**:
- Overview of container creation process
- Deep dive: [DETAILED_GUIDE.md](ct/DETAILED_GUIDE.md) - Complete reference with examples
- Reference to [misc/build.func/](misc/build.func/)
- Quick start for creating new containers

### [install/](install/) - Installation Scripts
Documentation for `/install` - Scripts that run inside containers to install applications.

**Includes**:
- Overview of 10-phase installation pattern
- Deep dive: [DETAILED_GUIDE.md](install/DETAILED_GUIDE.md) - Complete reference with examples
- Reference to [misc/tools.func/](misc/tools.func/)
- Alpine vs Debian differences

### [vm/](vm/) - Virtual Machine Scripts
Documentation for `/vm` - VM creation scripts using cloud-init provisioning.

**Includes**:
- Overview of VM provisioning
- Link to [misc/cloud-init.func/](misc/cloud-init.func/)
- VM vs Container comparison
- Cloud-init examples

### [tools/](tools/) - Tools & Utilities
Documentation for `/tools` - Management tools and add-ons.

**Includes**:
- Overview of tools structure
- Integration points
- Contributing new tools
- Common operations

### [api/](api/) - API Integration
Documentation for `/api` - Telemetry and API backend.

**Includes**:
- API overview
- Integration methods
- API endpoints
- Privacy information

### [misc/](misc/) - Function Libraries
Documentation for `/misc` - 9 core function libraries with complete references.

**Contains**:
- **build.func/** - Container orchestration (7 files)
- **core.func/** - Utilities and messaging (5 files)
- **error_handler.func/** - Error handling (5 files)
- **api.func/** - API integration (5 files)
- **install.func/** - Container setup (5 files)
- **tools.func/** - Package installation (6 files)
- **alpine-install.func/** - Alpine setup (5 files)
- **alpine-tools.func/** - Alpine tools (5 files)
- **cloud-init.func/** - VM provisioning (5 files)

---

## 🎓 **Learning Paths**

### Path 1: First-Time Contributor (2-3 hours)

1. [contribution/README.md](contribution/README.md) - Quick Start
2. Pick your area:
   - Containers → [ct/README.md](ct/README.md) + [ct/DETAILED_GUIDE.md](ct/DETAILED_GUIDE.md)
   - Installation → [install/README.md](install/README.md) + [install/DETAILED_GUIDE.md](install/DETAILED_GUIDE.md)
   - VMs → [vm/README.md](vm/README.md)
3. Study existing similar script
4. Create your contribution
5. Submit PR

### Path 2: Intermediate Developer (4-6 hours)

1. [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)
2. Dive into function libraries:
   - [misc/build.func/README.md](misc/build.func/README.md)
   - [misc/tools.func/README.md](misc/tools.func/README.md)
   - [misc/install.func/README.md](misc/install.func/README.md)
3. Study advanced examples
4. Create complex applications

### Path 3: Advanced Architect (8+ hours)

1. All of Intermediate Path
2. Study all 9 function libraries in depth
3. [DEFAULTS_SYSTEM_GUIDE.md](DEFAULTS_SYSTEM_GUIDE.md) - Configuration system
4. [DEV_MODE.md](DEV_MODE.md) - Debugging and development
5. Design new features or function libraries

### Path 4: Troubleshooter (30 minutes - 1 hour)

1. [EXIT_CODES.md](EXIT_CODES.md) - Find error code
2. [DEV_MODE.md](DEV_MODE.md) - Run with debugging
3. Check relevant function library docs
4. Review logs and fix

---

## 📊 **By the Numbers**

| Metric | Count |
|--------|:---:|
| **Documentation Files** | 63 |
| **Total Lines** | 15,000+ |
| **Function Libraries** | 9 |
| **Functions Documented** | 150+ |
| **Code Examples** | 50+ |
| **Flowcharts** | 15+ |
| **Do/Don't Sections** | 20+ |
| **Real-World Examples** | 30+ |

---

## 🔍 **Find It Fast**

### By Feature
- **How do I create a container?** → [ct/DETAILED_GUIDE.md](ct/DETAILED_GUIDE.md)
- **How do I create an install script?** → [install/DETAILED_GUIDE.md](install/DETAILED_GUIDE.md)
- **How do I create a VM?** → [vm/README.md](vm/README.md)
- **How do I install Node.js?** → [misc/tools.func/](misc/tools.func/)
- **How do I debug?** → [DEV_MODE.md](DEV_MODE.md)

### By Error
- **Exit code 206?** → [EXIT_CODES.md](EXIT_CODES.md)
- **Network failed?** → [misc/install.func/](misc/install.func/)
- **Package error?** → [misc/tools.func/](misc/tools.func/)

### By Role
- **Contributor** → [contribution/README.md](contribution/README.md)
- **Operator** → [DEFAULTS_SYSTEM_GUIDE.md](DEFAULTS_SYSTEM_GUIDE.md)
- **Developer** → [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)
- **Architect** → [misc/README.md](misc/README.md)

---

## ✅ **Documentation Features**

- ✅ **Project-mirrored structure** - Organized like the actual project
- ✅ **Complete function references** - Every function documented
- ✅ **Real-world examples** - Copy-paste ready code
- ✅ **Visual flowcharts** - ASCII diagrams of workflows
- ✅ **Integration guides** - How components connect
- ✅ **Troubleshooting** - Common issues and solutions
- ✅ **Best practices** - DO/DON'T sections throughout
- ✅ **Learning paths** - Structured curriculum by role
- ✅ **Quick references** - Fast lookup by error code
- ✅ **Comprehensive navigation** - This page

---

## 🚀 **Start Here**

**New to ProxmoxVE?** → [contribution/README.md](contribution/README.md)

**Looking for something specific?** → Choose your role above or browse by directory

**Need to debug?** → [EXIT_CODES.md](EXIT_CODES.md)

**Want to understand architecture?** → [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)

---

## 🤝 **Contributing Documentation**

Found an error? Want to improve docs?

1. See: [contribution/README.md](contribution/README.md) for full contribution guide
2. Open issue: [GitHub Issues](https://github.com/community-scripts/ProxmoxVE/issues)
3. Or submit PR with improvements

---

## 📝 **Status**

- **Last Updated**: December 2025
- **Version**: 2.3 (Consolidated & Reorganized)
- **Completeness**: ✅ 100% - All components documented
- **Quality**: ✅ Production-ready
- **Structure**: ✅ Clean and organized

---

**Welcome to ProxmoxVE! Start with [CONTRIBUTION_GUIDE.md](CONTRIBUTION_GUIDE.md) or choose your role above.** 🚀
