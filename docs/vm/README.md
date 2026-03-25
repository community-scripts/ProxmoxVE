# VM Scripts Documentation (/vm)

This directory contains comprehensive documentation for virtual machine creation scripts in the `/vm` directory.

## Overview

VM scripts (`vm/*.sh`) create full virtual machines (not containers) in Proxmox VE with complete operating systems and cloud-init provisioning.

## Documentation Structure

VM documentation parallels container documentation but focuses on VM-specific features.

## Key Resources

- **[misc/cloud-init.func/](../misc/cloud-init.func/)** - Cloud-init provisioning documentation
- **[CONTRIBUTION_GUIDE.md](../CONTRIBUTION_GUIDE.md)** - Contribution workflow
- **[EXIT_CODES.md](../EXIT_CODES.md)** - Exit code reference

## VM Creation Flow

```
vm/OsName-vm.sh (host-side)
    │
    ├─ Calls: build.func (orchestrator)
    │
    ├─ Variables: var_cpu, var_ram, var_disk, var_os
    │
    ├─ Uses: cloud-init.func (provisioning)
    │
    └─ Creates: KVM/QEMU VM
                │
                └─ Boots with: Cloud-init config
                               │
                               ├─ System phase
                               ├─ Config phase
                               └─ Final phase
```

## Available VM Scripts

See `/vm` directory for all VM creation scripts. Examples:

- `ubuntu2504-vm.sh` - Ubuntu 25.04 VM (Latest)
- `ubuntu2404-vm.sh` - Ubuntu 24.04 VM (LTS)
- `debian-13-vm.sh` - Debian 13 VM (Trixie)
- `archlinux-vm.sh` - Arch Linux VM
- `haos-vm.sh` - Home Assistant OS
- `mikrotik-routeros.sh` - MikroTik RouterOS
- `openwrt-vm.sh` - OpenWrt VM
- `opnsense-vm.sh` - OPNsense firewall
- `umbrel-os-vm.sh` - Umbrel OS VM
- And 10+ more...

## VM vs Container

| Feature | VM | Container |
|---------|:---:|:---:|
| Isolation | Full | Lightweight |
| Boot Time | Slower | Instant |
| Resource Use | Higher | Lower |
| Use Case | Full OS | Single app |
| Init System | systemd/etc | cloud-init |
| Storage | Disk image | Filesystem |

## Quick Start

To understand VM creation:

1. Read: [misc/cloud-init.func/README.md](../misc/cloud-init.func/README.md)
2. Study: A similar existing script in `/vm`
3. Understand cloud-init configuration
4. Test locally
5. Submit PR

## Contributing a New VM

1. Create `vm/osname-vm.sh`
2. Use cloud-init for provisioning
3. Follow VM script template
4. Test VM creation and boot
5. Submit PR

## Cloud-Init Provisioning

VMs are provisioned using cloud-init:

```yaml
#cloud-config
hostname: myvm
timezone: UTC

packages:
  - curl
  - wget

users:
  - name: ubuntu
    ssh_authorized_keys:
      - ssh-rsa AAAAB3...

bootcmd:
  - echo "VM starting..."

runcmd:
  - apt-get update
  - apt-get upgrade -y
```

## Common VM Operations

- **Create VM with cloud-init** → [misc/cloud-init.func/](../misc/cloud-init.func/)
- **Configure networking** → Cloud-init YAML documentation
- **Setup SSH keys** → [misc/cloud-init.func/CLOUD_INIT_FUNC_USAGE_EXAMPLES.md](../misc/cloud-init.func/CLOUD_INIT_FUNC_USAGE_EXAMPLES.md)
- **Debug VM creation** → [EXIT_CODES.md](../EXIT_CODES.md)

## VM Templates

Common VM templates available:

- **Ubuntu LTS** - Latest stable Ubuntu
- **Debian Stable** - Latest stable Debian
- **OPNsense** - Network security platform
- **Home Assistant** - Home automation
- **Kubernetes** - K3s lightweight cluster
- **Proxmox Backup** - Backup server

---

**Last Updated**: December 2025
**Maintainers**: community-scripts team
