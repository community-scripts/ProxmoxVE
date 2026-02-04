# Advanced Settings Wizard Reference

## Overview

The Advanced Settings wizard provides a 28-step interactive configuration for LXC container creation. It allows users to customize every aspect of the container while inheriting sensible defaults from the CT script.

## Key Features

- **Inherit App Defaults**: All `var_*` values from CT scripts pre-populate wizard fields
- **Back Navigation**: Press Cancel/Back to return to previous step
- **App Default Hints**: Each dialog shows `(App default: X)` to indicate script defaults
- **Full Customization**: Every configurable option is accessible

## Wizard Steps

| Step | Title                    | Variable(s)                       | Description                                           |
| ---- | ------------------------ | --------------------------------- | ----------------------------------------------------- |
| 1    | Container Type           | `var_unprivileged`                | Privileged (0) or Unprivileged (1) container          |
| 2    | Root Password            | `var_pw`                          | Set password or use automatic login                   |
| 3    | Container ID             | `var_ctid`                        | Unique container ID (auto-suggested)                  |
| 4    | Hostname                 | `var_hostname`                    | Container hostname                                    |
| 5    | Disk Size                | `var_disk`                        | Disk size in GB                                       |
| 6    | CPU Cores                | `var_cpu`                         | Number of CPU cores                                   |
| 7    | RAM Size                 | `var_ram`                         | RAM size in MiB                                       |
| 8    | Network Bridge           | `var_brg`                         | Network bridge (vmbr0, etc.)                          |
| 9    | IPv4 Configuration       | `var_net`, `var_gateway`          | DHCP or static IP with gateway                        |
| 10   | IPv6 Configuration       | `var_ipv6_method`                 | Auto, DHCP, Static, or None                           |
| 11   | MTU Size                 | `var_mtu`                         | Network MTU (default: 1500)                           |
| 12   | DNS Search Domain        | `var_searchdomain`                | DNS search domain                                     |
| 13   | DNS Server               | `var_ns`                          | Custom DNS server IP                                  |
| 14   | MAC Address              | `var_mac`                         | Custom MAC address (auto-generated if empty)          |
| 15   | VLAN Tag                 | `var_vlan`                        | VLAN tag ID                                           |
| 16   | Tags                     | `var_tags`                        | Container tags (comma/semicolon separated)            |
| 17   | SSH Settings             | `var_ssh`                         | SSH key selection and root access                     |
| 18   | FUSE Support             | `var_fuse`                        | Enable FUSE for rclone, mergerfs, AppImage            |
| 19   | TUN/TAP Support          | `var_tun`                         | Enable for VPN apps (WireGuard, OpenVPN, Tailscale)   |
| 20   | Nesting Support          | `var_nesting`                     | Enable for Docker, LXC in LXC, Podman                 |
| 21   | GPU Passthrough          | `var_gpu`                         | Auto-detect and pass through Intel/AMD/NVIDIA GPUs    |
| 22   | Keyctl Support           | `var_keyctl`                      | Enable for Docker, systemd-networkd                   |
| 23   | APT Cacher Proxy         | `var_apt_cacher`, `var_apt_cacher_ip` | Use apt-cacher-ng for faster downloads            |
| 24   | Container Timezone       | `var_timezone`                    | Set timezone (e.g., Europe/Berlin)                    |
| 25   | Container Protection     | `var_protection`                  | Prevent accidental deletion                           |
| 26   | Device Node Creation     | `var_mknod`                       | Allow mknod (experimental, kernel 5.3+)               |
| 27   | Mount Filesystems        | `var_mount_fs`                    | Allow specific mounts: nfs, cifs, fuse, etc.          |
| 28   | Verbose Mode & Confirm   | `var_verbose`                     | Enable verbose output + final confirmation            |

## Default Value Inheritance

The wizard inherits defaults from multiple sources:

```text
CT Script (var_*) → default.vars → app.vars → User Input
```

### Example: VPN Container (alpine-wireguard.sh)

```bash
# CT script sets:
var_tun="${var_tun:-1}"  # TUN enabled by default

# In Advanced Settings Step 19:
# Dialog shows: "(App default: 1)" and pre-selects "Yes"
```

### Example: Media Server (jellyfin.sh)

```bash
# CT script sets:
var_gpu="${var_gpu:-yes}"  # GPU enabled by default

# In Advanced Settings Step 21:
# Dialog shows: "(App default: yes)" and pre-selects "Yes"
```

## Feature Matrix

| Feature           | Variable         | When to Enable                                      |
| ----------------- | ---------------- | --------------------------------------------------- |
| FUSE              | `var_fuse`       | rclone, mergerfs, AppImage, SSHFS                   |
| TUN/TAP           | `var_tun`        | WireGuard, OpenVPN, Tailscale, VPN containers       |
| Nesting           | `var_nesting`    | Docker, Podman, LXC-in-LXC, systemd-nspawn          |
| GPU Passthrough   | `var_gpu`        | Plex, Jellyfin, Emby, Frigate, Ollama, ComfyUI      |
| Keyctl            | `var_keyctl`     | Docker (unprivileged), systemd-networkd             |
| Protection        | `var_protection` | Production containers, prevent accidental deletion  |
| Mknod             | `var_mknod`      | Device node creation (experimental)                 |
| Mount FS          | `var_mount_fs`   | NFS mounts, CIFS shares, custom filesystems         |
| APT Cacher        | `var_apt_cacher` | Speed up downloads with local apt-cacher-ng         |

## Confirmation Summary

Step 28 displays a comprehensive summary before creation:

```text
Container Type: Unprivileged
Container ID: 100
Hostname: jellyfin

Resources:
  Disk: 8 GB
  CPU: 2 cores
  RAM: 2048 MiB

Network:
  Bridge: vmbr0
  IPv4: dhcp
  IPv6: auto

Features:
  FUSE: no | TUN: no
  Nesting: Enabled | Keyctl: Disabled
  GPU: yes | Protection: No

Advanced:
  Timezone: Europe/Berlin
  APT Cacher: no
  Verbose: no
```

## Usage Examples

### Skip to Advanced Settings

```bash
# Run script, select "Advanced" from menu
bash -c "$(curl -fsSL https://...jellyfin.sh)"
# Then select option 3 "Advanced"
```

### Pre-set Defaults via Environment

```bash
# Set defaults before running
export var_cpu=4
export var_ram=4096
export var_gpu=yes
bash -c "$(curl -fsSL https://...jellyfin.sh)"
# Advanced settings will inherit these values
```

### Non-Interactive with All Options

```bash
# Set all variables for fully automated deployment
export var_unprivileged=1
export var_cpu=2
export var_ram=2048
export var_disk=8
export var_net=dhcp
export var_fuse=no
export var_tun=no
export var_gpu=yes
export var_nesting=1
export var_protection=no
export var_verbose=no
bash -c "$(curl -fsSL https://...jellyfin.sh)"
```

## Notes

- **Cancel at Step 1**: Exits the script entirely
- **Cancel at Steps 2-28**: Goes back to previous step
- **Empty fields**: Use default value
- **Keyctl**: Automatically enabled for unprivileged containers
- **Nesting**: Enabled by default (required for many apps)
