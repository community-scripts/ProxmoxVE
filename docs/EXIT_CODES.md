# Exit Code Reference

Comprehensive documentation of all exit codes used in ProxmoxVE scripts.

## Table of Contents

- [Generic/Shell Errors (1-255)](#genericshell-errors)
- [Package Manager Errors (100-101, 255)](#package-manager-errors)
- [Node.js/npm Errors (243-254)](#nodejsnpm-errors)
- [Python/pip Errors (210-212)](#pythonpip-errors)
- [Database Errors (231-254)](#database-errors)
- [Proxmox Custom Codes (200-231)](#proxmox-custom-codes)

---

## Generic/Shell Errors

Standard Unix/Linux exit codes used across all scripts.

| Code    | Description                             | Common Causes                             | Solutions                                      |
| ------- | --------------------------------------- | ----------------------------------------- | ---------------------------------------------- |
| **1**   | General error / Operation not permitted | Permission denied, general failure        | Check user permissions, run as root if needed  |
| **2**   | Misuse of shell builtins                | Syntax error in script                    | Review script syntax, check bash version       |
| **126** | Command cannot execute                  | Permission problem, not executable        | `chmod +x script.sh` or check file permissions |
| **127** | Command not found                       | Missing binary, wrong PATH                | Install required package, check PATH variable  |
| **128** | Invalid argument to exit                | Invalid exit code passed                  | Use exit codes 0-255 only                      |
| **130** | Terminated by Ctrl+C (SIGINT)           | User interrupted script                   | Expected behavior, no action needed            |
| **137** | Killed (SIGKILL)                        | Out of memory, forced termination         | Check memory usage, increase RAM allocation    |
| **139** | Segmentation fault                      | Memory access violation, corrupted binary | Reinstall package, check system stability      |
| **143** | Terminated (SIGTERM)                    | Graceful shutdown signal                  | Expected during container stops                |

---

## Package Manager Errors

APT, DPKG, and package installation errors.

| Code    | Description                | Common Causes                           | Solutions                                         |
| ------- | -------------------------- | --------------------------------------- | ------------------------------------------------- |
| **100** | APT: Package manager error | Broken packages, dependency conflicts   | `apt --fix-broken install`, `dpkg --configure -a` |
| **101** | APT: Configuration error   | Malformed sources.list, bad repo config | Check `/etc/apt/sources.list`, run `apt update`   |
| **255** | DPKG: Fatal internal error | Corrupted package database              | `dpkg --configure -a`, restore from backup        |

---

## Node.js/npm Errors

Node.js runtime and package manager errors.

| Code    | Description                                | Common Causes                  | Solutions                                      |
| ------- | ------------------------------------------ | ------------------------------ | ---------------------------------------------- |
| **243** | Node.js: Out of memory                     | JavaScript heap exhausted      | Increase `--max-old-space-size`, optimize code |
| **245** | Node.js: Invalid command-line option       | Wrong Node.js flags            | Check Node.js version, verify CLI options      |
| **246** | Node.js: Internal JavaScript Parse Error   | Syntax error in JS code        | Review JavaScript syntax, check dependencies   |
| **247** | Node.js: Fatal internal error              | Node.js runtime crash          | Update Node.js, check for known bugs           |
| **248** | Node.js: Invalid C++ addon / N-API failure | Native module incompatibility  | Rebuild native modules, update packages        |
| **249** | Node.js: Inspector error                   | Debug/inspect protocol failure | Disable inspector, check port conflicts        |
| **254** | npm/pnpm/yarn: Unknown fatal error         | Package manager crash          | Clear cache, reinstall package manager         |

---

## Python/pip Errors

Python runtime and package installation errors.

| Code    | Description                          | Common Causes                           | Solutions                                                |
| ------- | ------------------------------------ | --------------------------------------- | -------------------------------------------------------- |
| **210** | Python: Virtualenv missing or broken | venv not created, corrupted environment | `python3 -m venv venv`, recreate virtualenv              |
| **211** | Python: Dependency resolution failed | Conflicting package versions            | Use `pip install --upgrade`, check requirements.txt      |
| **212** | Python: Installation aborted         | EXTERNALLY-MANAGED, permission denied   | Use `--break-system-packages` or venv, check permissions |

---

## Database Errors

### PostgreSQL (231-234)

| Code    | Description             | Common Causes                      | Solutions                                             |
| ------- | ----------------------- | ---------------------------------- | ----------------------------------------------------- |
| **231** | Connection failed       | Server not running, wrong socket   | `systemctl start postgresql`, check connection string |
| **232** | Authentication failed   | Wrong credentials                  | Verify username/password, check `pg_hba.conf`         |
| **233** | Database does not exist | Database not created               | `CREATE DATABASE`, restore from backup                |
| **234** | Fatal error in query    | Syntax error, constraint violation | Review SQL syntax, check constraints                  |

### MySQL/MariaDB (241-244)

| Code    | Description             | Common Causes                      | Solutions                                            |
| ------- | ----------------------- | ---------------------------------- | ---------------------------------------------------- |
| **241** | Connection failed       | Server not running, wrong socket   | `systemctl start mysql`, check connection parameters |
| **242** | Authentication failed   | Wrong credentials                  | Verify username/password, grant privileges           |
| **243** | Database does not exist | Database not created               | `CREATE DATABASE`, restore from backup               |
| **244** | Fatal error in query    | Syntax error, constraint violation | Review SQL syntax, check constraints                 |

### MongoDB (251-254)

| Code    | Description           | Common Causes        | Solutions                                  |
| ------- | --------------------- | -------------------- | ------------------------------------------ |
| **251** | Connection failed     | Server not running   | `systemctl start mongod`, check port 27017 |
| **252** | Authentication failed | Wrong credentials    | Verify username/password, create user      |
| **253** | Database not found    | Database not created | Database auto-created on first write       |
| **254** | Fatal query error     | Invalid query syntax | Review MongoDB query syntax                |

---

## Proxmox Custom Codes

Custom exit codes specific to ProxmoxVE scripts.

### Container Creation Errors (200-209)

| Code    | Description                                    | Common Causes                                           | Solutions                                               |
| ------- | ---------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------- |
| **200** | Failed to create lock file                     | Permission denied, disk full                            | Check `/tmp` permissions, free disk space               |
| **203** | Missing CTID variable                          | Script configuration error                              | Set CTID in script or via prompt                        |
| **204** | Missing PCT_OSTYPE variable                    | Template selection failed                               | Verify template availability                            |
| **205** | Invalid CTID (<100)                            | CTID below minimum value                                | Use CTID ≥ 100 (1-99 reserved for Proxmox)              |
| **206** | CTID already in use                            | Container/VM with same ID exists                        | Check `pct list` and `/etc/pve/lxc/`, use different ID  |
| **207** | Password contains unescaped special characters | Special chars like `-`, `/`, `\`, `*` at start/end      | Avoid leading special chars, use alphanumeric passwords |
| **208** | Invalid configuration                          | DNS format (`.home` vs `home`), MAC format (`-` vs `:`) | Remove leading dots from DNS, use `:` in MAC addresses  |
| **209** | Container creation failed                      | Multiple possible causes                                | Check logs in `/tmp/pct_create_*.log`, verify template  |

### Cluster & Storage Errors (210, 214, 217)

| Code    | Description                       | Common Causes                      | Solutions                                                   |
| ------- | --------------------------------- | ---------------------------------- | ----------------------------------------------------------- |
| **210** | Cluster not quorate               | Cluster nodes down, network issues | Check cluster status: `pvecm status`, fix node connectivity |
| **211** | Timeout waiting for template lock | Concurrent download in progress    | Wait for other download to complete (60s timeout)           |
| **214** | Not enough storage space          | Disk full, quota exceeded          | Free disk space, increase storage allocation                |
| **217** | Storage does not support rootdir  | Wrong storage type selected        | Use storage supporting containers (dir, zfspool, lvm-thin)  |

### Container Verification Errors (215-216)

| Code    | Description                      | Common Causes                    | Solutions                                                 |
| ------- | -------------------------------- | -------------------------------- | --------------------------------------------------------- |
| **215** | Container created but not listed | Ghost state, incomplete creation | Check `/etc/pve/lxc/CTID.conf`, remove manually if needed |
| **216** | RootFS entry missing in config   | Incomplete container creation    | Delete container, retry creation                          |

### Template Errors (218, 220-223, 225)

| Code    | Description                               | Common Causes                                    | Solutions                                                   |
| ------- | ----------------------------------------- | ------------------------------------------------ | ----------------------------------------------------------- |
| **218** | Template file corrupted or incomplete     | Download interrupted, file <1MB, invalid archive | Delete template, run `pveam update && pveam download`       |
| **220** | Unable to resolve template path           | Template storage not accessible                  | Check storage availability, verify permissions              |
| **221** | Template file exists but not readable     | Permission denied                                | `chmod 644 template.tar.zst`, check storage permissions     |
| **222** | Template download failed after 3 attempts | Network issues, storage problems                 | Check internet connectivity, verify storage space           |
| **223** | Template not available after download     | Storage sync issue, I/O delay                    | Wait a few seconds, verify storage is mounted               |
| **225** | No template available for OS/Version      | Unsupported OS version, catalog outdated         | Run `pveam update`, check `pveam available -section system` |

### LXC Stack Errors (231)

| Code    | Description                    | Common Causes                               | Solutions                                    |
| ------- | ------------------------------ | ------------------------------------------- | -------------------------------------------- |
| **231** | LXC stack upgrade/retry failed | Outdated `pve-container`, Debian 13.1 issue | See [Debian 13.1 Fix Guide](#debian-131-fix) |

---

## Special Case: Debian 13.1 "unsupported version" Error

### Problem

```
TASK ERROR: unable to create CT 129 - unsupported debian version '13.1'
```

### Root Cause

Outdated `pve-container` package doesn't recognize Debian 13 (Trixie).

### Solutions

#### Option 1: Full System Upgrade (Recommended)

```bash
apt update
apt full-upgrade -y
reboot
```

Verify fix:

```bash
dpkg -l pve-container
# PVE 8: Should show 5.3.3+
# PVE 9: Should show 6.0.13+
```

#### Option 2: Update Only pve-container

```bash
apt update
apt install --only-upgrade pve-container -y
```

**Warning:** If Proxmox fails to boot after this, your system was inconsistent. Perform Option 1 instead.

#### Option 3: Verify Repository Configuration

Many users disable Enterprise repos but forget to add no-subscription repos.

**For PVE 9 (Trixie):**

```bash
cat /etc/apt/sources.list.d/pve-no-subscription.list
```

Should contain:

```
deb http://download.proxmox.com/debian/pve trixie pve-no-subscription
deb http://download.proxmox.com/debian/ceph-squid trixie no-subscription
```

**For PVE 8 (Bookworm):**

```
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription
```

Then:

```bash
apt update
apt full-upgrade -y
```

### Reference

Official discussion: [GitHub #8126](https://github.com/community-scripts/ProxmoxVE/discussions/8126)

---

## Troubleshooting Tips

### Finding Error Details

1. **Check logs:**

   ```bash
   tail -n 50 /tmp/pct_create_*.log
   ```

2. **Enable verbose mode:**

   ```bash
   bash -x script.sh  # Shows every command executed
   ```

3. **Check container status:**

   ```bash
   pct list
   pct status CTID
   ```

4. **Verify storage:**
   ```bash
   pvesm status
   df -h
   ```

### Common Patterns

- **Exit 0 with error message:** Configuration validation failed (check DNS, MAC, password format)
- **Exit 206 but container not visible:** Ghost container state - check `/etc/pve/lxc/` manually
- **Exit 209 generic error:** Check `/tmp/pct_create_*.log` for specific `pct create` failure reason
- **Exit 218 or 222:** Template issues - delete and re-download template

---

## Quick Reference Chart

| Exit Code Range | Category           | Typical Issue                               |
| --------------- | ------------------ | ------------------------------------------- |
| 1-2, 126-143    | Shell/System       | Permissions, signals, missing commands      |
| 100-101, 255    | Package Manager    | APT/DPKG errors, broken packages            |
| 200-209         | Container Creation | CTID, password, configuration               |
| 210-217         | Storage/Cluster    | Disk space, quorum, storage type            |
| 218-225         | Templates          | Download, corruption, availability          |
| 231-254         | Databases/Runtime  | PostgreSQL, MySQL, MongoDB, Node.js, Python |

---

## Contributing

Found an undocumented exit code or have a solution to share? Please:

1. Open an issue on [GitHub](https://github.com/community-scripts/ProxmoxVE/issues)
2. Include:
   - Exit code number
   - Error message
   - Steps to reproduce
   - Solution that worked for you

---

_Last updated: November 2025_
_ProxmoxVE Version: 2.x_
