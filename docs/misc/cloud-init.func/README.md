# cloud-init.func Documentation

## Overview

The `cloud-init.func` file provides cloud-init configuration and VM initialization functions for Proxmox VE virtual machines. It handles user data, cloud-config generation, and VM setup automation.

## Purpose and Use Cases

- **VM Cloud-Init Setup**: Generate and apply cloud-init configurations for VMs
- **User Data Generation**: Create user-data scripts for VM initialization
- **Cloud-Config**: Generate cloud-config YAML for VM provisioning
- **SSH Key Management**: Setup SSH keys for VM access
- **Network Configuration**: Configure networking for VMs
- **Automated VM Provisioning**: Complete VM setup without manual intervention

## Quick Reference

### Key Function Groups
- **Cloud-Init Core**: Generate and apply cloud-init configurations
- **User Data**: Create initialization scripts for VMs
- **SSH Setup**: Deploy SSH keys automatically
- **Network Configuration**: Setup networking during VM provisioning
- **VM Customization**: Apply custom settings to VMs

### Dependencies
- **External**: `cloud-init`, `curl`, `qemu-img`
- **Internal**: Uses functions from `core.func`, `error_handler.func`

### Integration Points
- Used by: VM creation scripts (vm/*.sh)
- Uses: Environment variables from build.func
- Provides: VM initialization and cloud-init services

## Documentation Files

### 📊 [CLOUD_INIT_FUNC_FLOWCHART.md](./CLOUD_INIT_FUNC_FLOWCHART.md)
Visual execution flows showing cloud-init generation and VM provisioning workflows.

### 📚 [CLOUD_INIT_FUNC_FUNCTIONS_REFERENCE.md](./CLOUD_INIT_FUNC_FUNCTIONS_REFERENCE.md)
Complete alphabetical reference of all cloud-init functions.

### 💡 [CLOUD_INIT_FUNC_USAGE_EXAMPLES.md](./CLOUD_INIT_FUNC_USAGE_EXAMPLES.md)
Practical examples for VM cloud-init setup and customization.

### 🔗 [CLOUD_INIT_FUNC_INTEGRATION.md](./CLOUD_INIT_FUNC_INTEGRATION.md)
How cloud-init.func integrates with VM creation and Proxmox workflows.

## Key Features

### Cloud-Init Configuration
- **User Data Generation**: Create custom initialization scripts
- **Cloud-Config YAML**: Generate standardized cloud-config
- **SSH Keys**: Automatically deploy public keys
- **Package Installation**: Install packages during VM boot
- **Custom Commands**: Run arbitrary commands on first boot

### VM Network Setup
- **DHCP Configuration**: Configure DHCP for automatic IP assignment
- **Static IP Setup**: Configure static IP addresses
- **IPv6 Support**: Enable IPv6 on VMs
- **DNS Configuration**: Set DNS servers for VM
- **Firewall Rules**: Basic firewall configuration

### Security Features
- **SSH Key Injection**: Deploy SSH keys during VM creation
- **Disable Passwords**: Disable password authentication
- **Sudoers Configuration**: Setup sudo access
- **User Management**: Create and configure users

## Function Categories

### 🔹 Cloud-Init Core Functions
- `generate_cloud_init()` - Create cloud-init configuration
- `generate_user_data()` - Generate user-data script
- `apply_cloud_init()` - Apply cloud-init to VM
- `validate_cloud_init()` - Validate cloud-config syntax

### 🔹 SSH & Security Functions
- `setup_ssh_keys()` - Deploy SSH public keys
- `setup_sudo()` - Configure sudoers
- `create_user()` - Create new user account
- `disable_password_auth()` - Disable password login

### 🔹 Network Configuration Functions
- `setup_dhcp()` - Configure DHCP networking
- `setup_static_ip()` - Configure static IP
- `setup_dns()` - Configure DNS servers
- `setup_ipv6()` - Enable IPv6 support

### 🔹 VM Customization Functions
- `install_packages()` - Install packages during boot
- `run_custom_commands()` - Execute custom scripts
- `configure_hostname()` - Set VM hostname
- `configure_timezone()` - Set VM timezone

## Cloud-Init Workflow

```
VM Created
    ↓
cloud-init (system) boot phase
    ↓
User-Data Script Execution
    ↓
├─ Install packages
├─ Deploy SSH keys
├─ Configure network
└─ Create users
    ↓
cloud-init config phase
    ↓
Apply cloud-config settings
    ↓
cloud-init final phase
    ↓
VM Ready for Use
```

## Common Usage Patterns

### Basic VM Setup with Cloud-Init
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# Generate cloud-init configuration
cat > cloud-init.yaml <<EOF
#cloud-config
hostname: myvm
timezone: UTC

packages:
  - curl
  - wget
  - git

users:
  - name: ubuntu
    ssh_authorized_keys:
      - ssh-rsa AAAAB3...
    sudo: ALL=(ALL) NOPASSWD:ALL

bootcmd:
  - echo "VM initializing..."

runcmd:
  - apt-get update
  - apt-get upgrade -y
EOF

# Apply to VM
qm set VMID --cicustom local:snippets/cloud-init.yaml
```

### With SSH Key Deployment
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# Get SSH public key
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)

# Generate cloud-init with SSH key
generate_user_data > user-data.txt

# Inject SSH key
setup_ssh_keys "$VMID" "$SSH_KEY"

# Create VM with cloud-init
qm create $VMID ... --cicustom local:snippets/user-data
```

### Network Configuration
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# Static IP setup
setup_static_ip "192.168.1.100" "255.255.255.0" "192.168.1.1"

# DNS configuration
setup_dns "8.8.8.8 8.8.4.4"

# IPv6 support
setup_ipv6
```

## Best Practices

### ✅ DO
- Validate cloud-config syntax before applying
- Use cloud-init for automated setup
- Deploy SSH keys for secure access
- Test cloud-init configuration in non-production first
- Use DHCP for easier VM deployment
- Document custom cloud-init configurations
- Version control cloud-init templates

### ❌ DON'T
- Use weak SSH keys or passwords
- Leave SSH password authentication enabled
- Hardcode credentials in cloud-init
- Skip validation of cloud-config
- Use untrusted cloud-init sources
- Forget to set timezone on VMs
- Mix cloud-init versions

## Cloud-Config Format

### Example Cloud-Config
```yaml
#cloud-config
# This is a comment

# System configuration
hostname: myvm
timezone: UTC
package_upgrade: true

# Packages to install
packages:
  - curl
  - wget
  - git
  - build-essential

# SSH keys for users
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC...

# Users to create
users:
  - name: ubuntu
    home: /home/ubuntu
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ssh-rsa AAAAB3...

# Commands to run on boot
runcmd:
  - apt-get update
  - apt-get upgrade -y
  - systemctl restart ssh

# Files to create
write_files:
  - path: /etc/profile.d/custom.sh
    content: |
      export CUSTOM_VAR="value"
```

## VM Network Configuration

### DHCP Configuration
```bash
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      dhcp6: true
```

### Static IP Configuration
```bash
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

## Troubleshooting

### "Cloud-Init Configuration Not Applied"
```bash
# Check cloud-init status in VM
cloud-init status
cloud-init status --long

# View cloud-init logs
tail /var/log/cloud-init.log
```

### "SSH Keys Not Deployed"
```bash
# Verify SSH key in cloud-config
grep ssh_authorized_keys user-data.txt

# Check permissions
ls -la ~/.ssh/authorized_keys
```

### "Network Not Configured"
```bash
# Check network configuration
ip addr show
ip route show

# View netplan (if used)
cat /etc/netplan/*.yaml
```

### "Packages Failed to Install"
```bash
# Check cloud-init package log
tail /var/log/cloud-init-output.log

# Manual package installation
apt-get update && apt-get install -y package-name
```

## Related Documentation

- **[install.func/](../install.func/)** - Container installation (similar workflow)
- **[core.func/](../core.func/)** - Utility functions
- **[error_handler.func/](../error_handler.func/)** - Error handling
- **[UPDATED_APP-install.md](../../UPDATED_APP-install.md)** - Application setup guide
- **Proxmox Docs**: https://pve.proxmox.com/wiki/Cloud-Init

## Recent Updates

### Version 2.0 (Dec 2025)
- ✅ Enhanced cloud-init validation
- ✅ Improved SSH key deployment
- ✅ Better network configuration support
- ✅ Added IPv6 support
- ✅ Streamlined user and package setup

---

**Last Updated**: December 2025
**Maintainers**: community-scripts team
**License**: MIT
