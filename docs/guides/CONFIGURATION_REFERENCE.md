# Configuration Reference

**Complete reference for all configuration variables and options in community-scripts for Proxmox VE.**

---

## Table of Contents

1. [Variable Naming Convention](#variable-naming-convention)
2. [Complete Variable Reference](#complete-variable-reference)
3. [Resource Configuration](#resource-configuration)
4. [Network Configuration](#network-configuration)
5. [IPv6 Configuration](#ipv6-configuration)
6. [SSH Configuration](#ssh-configuration)
7. [Container Features](#container-features)
8. [Storage Configuration](#storage-configuration)
9. [Security Settings](#security-settings)
10. [Advanced Options](#advanced-options)
11. [Quick Reference Table](#quick-reference-table)

---

## Variable Naming Convention

All configuration variables follow a consistent pattern:

```
var_<setting>=<value>
```

**Rules:**
- ✅ Always starts with `var_`
- ✅ Lowercase letters only
- ✅ Underscores for word separation
- ✅ No spaces around `=`
- ✅ Values can be quoted if needed

**Examples:**
```bash
# ✓ Correct
var_cpu=4
var_hostname=myserver
var_ssh_authorized_key=ssh-rsa AAAA...

# ✗ Wrong
CPU=4                    # Missing var_ prefix
var_CPU=4                # Uppercase not allowed
var_cpu = 4              # Spaces around =
var-cpu=4                # Hyphens not allowed
```

---

## Complete Variable Reference

### var_unprivileged

**Type:** Boolean (0 or 1)
**Default:** `1` (unprivileged)
**Description:** Determines if container runs unprivileged (recommended) or privileged.

```bash
var_unprivileged=1    # Unprivileged (safer, recommended)
var_unprivileged=0    # Privileged (less secure, more features)
```

**When to use privileged (0):**
- Hardware access required
- Certain kernel modules needed
- Legacy applications
- Nested virtualization with full features

**Security Impact:**
- Unprivileged: Container root is mapped to unprivileged user on host
- Privileged: Container root = host root (security risk)

---

### var_cpu

**Type:** Integer
**Default:** Varies by app (usually 1-4)
**Range:** 1 to host CPU count
**Description:** Number of CPU cores allocated to container.

```bash
var_cpu=1     # Single core (minimal)
var_cpu=2     # Dual core (typical)
var_cpu=4     # Quad core (recommended for apps)
var_cpu=8     # High performance
```

**Best Practices:**
- Start with 2 cores for most applications
- Monitor usage with `pct exec <id> -- htop`
- Can be changed after creation
- Consider host CPU count (don't over-allocate)

---

### var_ram

**Type:** Integer (MB)
**Default:** Varies by app (usually 512-2048)
**Range:** 512 MB to host RAM
**Description:** Amount of RAM in megabytes.

```bash
var_ram=512      # 512 MB (minimal)
var_ram=1024     # 1 GB (typical)
var_ram=2048     # 2 GB (comfortable)
var_ram=4096     # 4 GB (recommended for databases)
var_ram=8192     # 8 GB (high memory apps)
```

**Conversion Guide:**
```
512 MB   = 0.5 GB
1024 MB  = 1 GB
2048 MB  = 2 GB
4096 MB  = 4 GB
8192 MB  = 8 GB
16384 MB = 16 GB
```

**Best Practices:**
- Minimum 512 MB for basic Linux
- 1 GB for typical applications
- 2-4 GB for web servers, databases
- Monitor with `free -h` inside container

---

### var_disk

**Type:** Integer (GB)
**Default:** Varies by app (usually 2-8)
**Range:** 0.001 GB to storage capacity
**Description:** Root disk size in gigabytes.

```bash
var_disk=2      # 2 GB (minimal OS only)
var_disk=4      # 4 GB (typical)
var_disk=8      # 8 GB (comfortable)
var_disk=20     # 20 GB (recommended for apps)
var_disk=50     # 50 GB (large applications)
var_disk=100    # 100 GB (databases, media)
```

**Important Notes:**
- Can be expanded after creation (not reduced)
- Actual space depends on storage type
- Thin provisioning supported on most storage
- Plan for logs, data, updates

**Recommended Sizes by Use Case:**
```
Basic Linux container:     4 GB
Web server (Nginx/Apache): 8 GB
Application server:        10-20 GB
Database server:          20-50 GB
Docker host:              30-100 GB
Media server:             100+ GB
```

---

### var_hostname

**Type:** String
**Default:** Application name
**Max Length:** 63 characters
**Description:** Container hostname (FQDN format allowed).

```bash
var_hostname=myserver
var_hostname=pihole
var_hostname=docker-01
var_hostname=web.example.com
```

**Rules:**
- Lowercase letters, numbers, hyphens
- Cannot start or end with hyphen
- No underscores allowed
- No spaces

**Best Practices:**
```bash
# ✓ Good
var_hostname=web-server
var_hostname=db-primary
var_hostname=app.domain.com

# ✗ Avoid
var_hostname=Web_Server    # Uppercase, underscore
var_hostname=-server       # Starts with hyphen
var_hostname=my server     # Contains space
```

---

### var_brg

**Type:** String
**Default:** `vmbr0`
**Description:** Network bridge interface.

```bash
var_brg=vmbr0    # Default Proxmox bridge
var_brg=vmbr1    # Custom bridge
var_brg=vmbr2    # Isolated network
```

**Common Setups:**
```
vmbr0 → Main network (LAN)
vmbr1 → Guest network
vmbr2 → DMZ
vmbr3 → Management
vmbr4 → Storage network
```

**Check available bridges:**
```bash
ip link show | grep vmbr
# or
brctl show
```

---

### var_net

**Type:** String
**Options:** `dhcp` or `static`
**Default:** `dhcp`
**Description:** IPv4 network configuration method.

```bash
var_net=dhcp     # Automatic IP via DHCP
var_net=static   # Manual IP configuration
```

**DHCP Mode:**
- Automatic IP assignment
- Easy setup
- Good for development
- Requires DHCP server on network

**Static Mode:**
- Fixed IP address
- Requires gateway configuration
- Better for servers
- Configure via advanced settings or after creation

---

### var_gateway

**Type:** IPv4 Address
**Default:** Auto-detected from host
**Description:** Network gateway IP address.

```bash
var_gateway=192.168.1.1
var_gateway=10.0.0.1
var_gateway=172.16.0.1
```

**Auto-detection:**
If not specified, system detects gateway from host:
```bash
ip route | grep default
```

**When to specify:**
- Multiple gateways available
- Custom routing setup
- Different network segment

---

### var_vlan

**Type:** Integer
**Range:** 1-4094
**Default:** None
**Description:** VLAN tag for network isolation.

```bash
var_vlan=10      # VLAN 10
var_vlan=100     # VLAN 100
var_vlan=200     # VLAN 200
```

**Common VLAN Schemes:**
```
VLAN 10  → Management
VLAN 20  → Servers
VLAN 30  → Desktops
VLAN 40  → Guest WiFi
VLAN 50  → IoT devices
VLAN 99  → DMZ
```

**Requirements:**
- Switch must support VLANs
- Proxmox bridge configured for VLAN aware
- Gateway on same VLAN

---

### var_mtu

**Type:** Integer
**Default:** `1500`
**Range:** 68-9000
**Description:** Maximum Transmission Unit size.

```bash
var_mtu=1500     # Standard Ethernet
var_mtu=1492     # PPPoE
var_mtu=9000     # Jumbo frames
```

**Common Values:**
```
1500 → Standard Ethernet (default)
1492 → PPPoE connections
1400 → Some VPN setups
9000 → Jumbo frames (10GbE networks)
```

**When to change:**
- Jumbo frames for performance on 10GbE
- PPPoE internet connections
- VPN tunnels with overhead
- Specific network requirements

---

### var_mac

**Type:** MAC Address
**Format:** `XX:XX:XX:XX:XX:XX`
**Default:** Auto-generated
**Description:** Container MAC address.

```bash
var_mac=02:00:00:00:00:01
var_mac=DE:AD:BE:EF:00:01
```

**When to specify:**
- MAC-based licensing
- Static DHCP reservations
- Network access control
- Cloning configurations

**Best Practices:**
- Use locally administered addresses (2nd bit set)
- Start with `02:`, `06:`, `0A:`, `0E:`
- Avoid vendor OUIs
- Document custom MACs

---

### var_ipv6_method

**Type:** String
**Options:** `auto`, `dhcp`, `static`, `none`, `disable`
**Default:** `none`
**Description:** IPv6 configuration method.

```bash
var_ipv6_method=auto      # SLAAC (auto-configuration)
var_ipv6_method=dhcp      # DHCPv6
var_ipv6_method=static    # Manual configuration
var_ipv6_method=none      # IPv6 enabled but not configured
var_ipv6_method=disable   # IPv6 completely disabled
```

**Detailed Options:**

**auto (SLAAC)**
- Stateless Address Auto-Configuration
- Router advertisements
- No DHCPv6 server needed
- Recommended for most cases

**dhcp (DHCPv6)**
- Stateful configuration
- Requires DHCPv6 server
- More control over addressing

**static**
- Manual IPv6 address
- Manual gateway
- Full control

**none**
- IPv6 stack active
- No address configured
- Can configure later

**disable**
- IPv6 completely disabled at kernel level
- Use when IPv6 causes issues
- Sets `net.ipv6.conf.all.disable_ipv6=1`

---

### var_ns

**Type:** IP Address
**Default:** Auto (from host)
**Description:** DNS nameserver IP.

```bash
var_ns=8.8.8.8           # Google DNS
var_ns=1.1.1.1           # Cloudflare DNS
var_ns=9.9.9.9           # Quad9 DNS
var_ns=192.168.1.1       # Local DNS
```

**Common DNS Servers:**
```
8.8.8.8, 8.8.4.4         → Google Public DNS
1.1.1.1, 1.0.0.1         → Cloudflare DNS
9.9.9.9, 149.112.112.112 → Quad9 DNS
208.67.222.222           → OpenDNS
192.168.1.1              → Local router/Pi-hole
```

---

### var_ssh

**Type:** Boolean
**Options:** `yes` or `no`
**Default:** `no`
**Description:** Enable SSH server in container.

```bash
var_ssh=yes      # SSH server enabled
var_ssh=no       # SSH server disabled (console only)
```

**When enabled:**
- OpenSSH server installed
- Started on boot
- Port 22 open
- Root login allowed

**Security Considerations:**
- Disable if not needed
- Use SSH keys instead of passwords
- Consider non-standard port
- Firewall rules recommended

---

### var_ssh_authorized_key

**Type:** String (SSH public key)
**Default:** None
**Description:** SSH public key for root user.

```bash
var_ssh_authorized_key=ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... user@host
var_ssh_authorized_key=ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... user@host
```

**Supported Key Types:**
- RSA (2048-4096 bits)
- Ed25519 (recommended)
- ECDSA
- DSA (deprecated)

**How to get your public key:**
```bash
cat ~/.ssh/id_rsa.pub
# or
cat ~/.ssh/id_ed25519.pub
```

**Multiple keys:**
Separate with newlines (in file) or use multiple deployments.

---

### var_pw

**Type:** String
**Default:** Empty (auto-login)
**Description:** Root password.

```bash
var_pw=SecurePassword123!    # Set password
var_pw=                      # Auto-login (empty)
```

**Auto-login behavior:**
- No password required for console
- Automatic login on console access
- SSH still requires key if enabled
- Suitable for development

**Password best practices:**
- Minimum 12 characters
- Mix upper/lower/numbers/symbols
- Use password manager
- Rotate regularly

---

### var_nesting

**Type:** Boolean (0 or 1)
**Default:** `1`
**Description:** Allow nested containers (required for Docker).

```bash
var_nesting=1    # Nested containers allowed
var_nesting=0    # Nested containers disabled
```

**Required for:**
- Docker
- LXC inside LXC
- Systemd features
- Container orchestration

**Security Impact:**
- Slightly reduced isolation
- Required for container platforms
- Generally safe when unprivileged

---

### var_diagnostics

**Type:** Boolean (yes or no)
**Default:** `yes`
**Description:** Determines if anonymous telemetry and diagnostic data is sent to Community-Scripts API.

```bash
var_diagnostics=yes      # Allow telemetry (helps us improve scripts)
var_diagnostics=no       # Disable all telemetry
```

**Privacy & Usage:**
- Data is strictly anonymous (random session ID)
- Reports success/failure of installations
- Maps error codes (e.g., APT lock, out of RAM)
- No user-specific data, hostnames, or secret keys are ever sent

---

### var_gpu

**Type:** Boolean/Toggle
**Options:** `yes` or `no`
**Default:** `no`
**Description:** Enable GPU passthrough for the container.

```bash
var_gpu=yes      # Enable GPU passthrough (auto-detect)
var_gpu=no       # Disable GPU passthrough (default)
```

**Features enabled:**
- Auto-detects Intel (QuickSync), NVIDIA, and AMD GPUs
- Passes through `/dev/dri` and render nodes
- Configures appropriate container permissions
- Crucial for media servers (Plex, Jellyfin, Immich)

**Prerequisites:**
- Host drivers installed correctly
- Hardware present and visible to Proxmox
- IOMMU enabled (for some configurations)

---

### var_tun

**Type:** Boolean/Toggle
**Options:** `yes` or `no`
**Default:** `no`
**Description:** Enable TUN/TAP device support.

```bash
var_tun=yes      # Enable TUN/TAP support
var_tun=no       # Disable TUN/TAP support (default)
```

**Required for:**
- VPN software (WireGuard, OpenVPN)
- Network tunneling (Tailscale, ZeroTier)
- Custom network bridges

---

### var_keyctl

**Type:** Boolean (0 or 1)
**Default:** `0`
**Description:** Enable keyctl system call.

```bash
var_keyctl=1     # Keyctl enabled
var_keyctl=0     # Keyctl disabled
```

**Required for:**
- Docker in some configurations
- Systemd keyring features
- Encryption key management
- Some authentication systems

---

### var_fuse

**Type:** Boolean/Toggle
**Options:** `yes` or `no`
**Default:** `no`
**Description:** Enable FUSE filesystem support.

```bash
var_fuse=yes     # FUSE enabled
var_fuse=no      # FUSE disabled
```

**Required for:**
- sshfs
- AppImage
- Some backup tools
- User-space filesystems

---

### var_mknod

**Type:** Boolean (0 or 1)
**Default:** `0`
**Description:** Allow device node creation.

```bash
var_mknod=1      # Device nodes allowed
var_mknod=0      # Device nodes disabled
```

**Requires:**
- Kernel 5.3+
- Experimental feature
- Use with caution

---

### var_mount_fs

**Type:** String (comma-separated)
**Default:** Empty
**Description:** Allowed mountable filesystems.

```bash
var_mount_fs=nfs
var_mount_fs=nfs,cifs
var_mount_fs=ext4,xfs,nfs
```

**Common Options:**
```
nfs      → NFS network shares
cifs     → SMB/CIFS shares
ext4     → Ext4 filesystems
xfs      → XFS filesystems
btrfs    → Btrfs filesystems
```

---

### var_protection

**Type:** Boolean
**Options:** `yes` or `no`
**Default:** `no`
**Description:** Prevent accidental deletion.

```bash
var_protection=yes    # Protected from deletion
var_protection=no     # Can be deleted normally
```

**When protected:**
- Cannot delete via GUI
- Cannot delete via `pct destroy`
- Must disable protection first
- Good for production containers

---

### var_tags

**Type:** String (comma-separated)
**Default:** `community-script`
**Description:** Container tags for organization.

```bash
var_tags=production
var_tags=production,webserver
var_tags=dev,testing,temporary
```

**Best Practices:**
```bash
# Environment tags
var_tags=production
var_tags=development
var_tags=staging

# Function tags
var_tags=webserver,nginx
var_tags=database,postgresql
var_tags=cache,redis

# Project tags
var_tags=project-alpha,frontend
var_tags=customer-xyz,billing

# Combined
var_tags=production,webserver,project-alpha
```

---

### var_timezone

**Type:** String (TZ database format)
**Default:** Host timezone
**Description:** Container timezone.

```bash
var_timezone=Europe/Berlin
var_timezone=America/New_York
var_timezone=Asia/Tokyo
```

**Common Timezones:**
```
Europe/London
Europe/Berlin
Europe/Paris
America/New_York
America/Chicago
America/Los_Angeles
Asia/Tokyo
Asia/Singapore
Australia/Sydney
UTC
```

**List all timezones:**
```bash
timedatectl list-timezones
```

---

### var_verbose

**Type:** Boolean
**Options:** `yes` or `no`
**Default:** `no`
**Description:** Enable verbose output.

```bash
var_verbose=yes    # Show all commands
var_verbose=no     # Silent mode
```

**When enabled:**
- Shows all executed commands
- Displays detailed progress
- Useful for debugging
- More log output

---

### var_apt_cacher

**Type:** Boolean
**Options:** `yes` or `no`
**Default:** `no`
**Description:** Use APT caching proxy.

```bash
var_apt_cacher=yes
var_apt_cacher=no
```

**Benefits:**
- Faster package installs
- Reduced bandwidth
- Offline package cache
- Speeds up multiple containers

---

### var_apt_cacher_ip

**Type:** IP Address
**Default:** None
**Description:** APT cacher proxy IP.

```bash
var_apt_cacher=yes
var_apt_cacher_ip=192.168.1.100
```

**Setup apt-cacher-ng:**
```bash
apt install apt-cacher-ng
# Runs on port 3142
```

---

### var_container_storage

**Type:** String
**Default:** Auto-detected
**Description:** Storage for container.

```bash
var_container_storage=local
var_container_storage=local-zfs
var_container_storage=pve-storage
```

**List available storage:**
```bash
pvesm status
```

---

### var_template_storage

**Type:** String
**Default:** Auto-detected
**Description:** Storage for templates.

```bash
var_template_storage=local
var_template_storage=nfs-templates
```

---

## Quick Reference Table

| Variable | Type | Default | Example |
|----------|------|---------|---------|
| `var_unprivileged` | 0/1 | 1 | `var_unprivileged=1` |
| `var_cpu` | int | varies | `var_cpu=4` |
| `var_ram` | int (MB) | varies | `var_ram=4096` |
| `var_disk` | int (GB) | varies | `var_disk=20` |
| `var_hostname` | string | app name | `var_hostname=server` |
| `var_brg` | string | vmbr0 | `var_brg=vmbr1` |
| `var_net` | dhcp/static | dhcp | `var_net=dhcp` |
| `var_gateway` | IP | auto | `var_gateway=192.168.1.1` |
| `var_ipv6_method` | string | none | `var_ipv6_method=disable` |
| `var_vlan` | int | - | `var_vlan=100` |
| `var_mtu` | int | 1500 | `var_mtu=9000` |
| `var_mac` | MAC | auto | `var_mac=02:00:00:00:00:01` |
| `var_ns` | IP | auto | `var_ns=8.8.8.8` |
| `var_ssh` | yes/no | no | `var_ssh=yes` |
| `var_ssh_authorized_key` | string | - | `var_ssh_authorized_key=ssh-rsa...` |
| `var_pw` | string | empty | `var_pw=password` |
| `var_nesting` | 0/1 | 1 | `var_nesting=1` |
| `var_keyctl` | 0/1 | 0 | `var_keyctl=1` |
| `var_fuse` | 0/1 | 0 | `var_fuse=1` |
| `var_mknod` | 0/1 | 0 | `var_mknod=1` |
| `var_mount_fs` | string | - | `var_mount_fs=nfs,cifs` |
| `var_protection` | yes/no | no | `var_protection=yes` |
| `var_tags` | string | community-script | `var_tags=prod,web` |
| `var_timezone` | string | host TZ | `var_timezone=Europe/Berlin` |
| `var_verbose` | yes/no | no | `var_verbose=yes` |
| `var_apt_cacher` | yes/no | no | `var_apt_cacher=yes` |
| `var_apt_cacher_ip` | IP | - | `var_apt_cacher_ip=192.168.1.10` |
| `var_container_storage` | string | auto | `var_container_storage=local-zfs` |
| `var_template_storage` | string | auto | `var_template_storage=local` |

---

## See Also

- [Defaults System Guide](DEFAULTS_GUIDE.md)
- [Unattended Deployments](UNATTENDED_DEPLOYMENTS.md)
- [Security Best Practices](SECURITY_GUIDE.md)
- [Network Configuration](NETWORK_GUIDE.md)
