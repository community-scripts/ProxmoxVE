# Dev Mode - Debugging & Development Guide

Development modes provide powerful debugging and testing capabilities for container creation and installation processes.

## Quick Start

```bash
# Single mode
export dev_mode="motd"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/wallabag.sh)"

# Multiple modes (comma-separated)
export dev_mode="motd,keep,trace"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/wallabag.sh)"

# Combine with verbose output
export var_verbose="yes"
export dev_mode="pause,logs"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/wallabag.sh)"
```

## Available Modes

### 1. **motd** - Early SSH/MOTD Setup

Sets up SSH access and MOTD **before** the main application installation.

**Use Case**:

- Quick access to container for manual debugging
- Continue installation manually if something goes wrong
- Verify container networking before main install

**Behavior**:

```
✔ Container created
✔ Network configured
[DEV] Setting up MOTD and SSH before installation
✔ [DEV] MOTD/SSH ready - container accessible
# Container is now accessible via SSH while installation proceeds
```

**Combined with**: `keep`, `breakpoint`, `logs`

---

### 2. **keep** - Preserve Container on Failure

Never delete the container when installation fails. Skips cleanup prompt.

**Use Case**:

- Repeated tests of the same installation
- Debugging failed installations
- Manual fix attempts

**Behavior**:

```
✖ Installation failed in container 107 (exit code: 1)
✔ Container creation log: /tmp/create-lxc-107-abc12345.log
✔ Installation log: /tmp/install-lxc-107-abc12345.log

🔧 [DEV] Keep mode active - container 107 preserved
root@proxmox:~#
```

**Container remains**: `pct enter 107` to access and debug

**Combined with**: `motd`, `trace`, `logs`

---

### 3. **trace** - Bash Command Tracing

Enables `set -x` for complete command-line tracing. Shows every command before execution.

**Use Case**:

- Deep debugging of installation logic
- Understanding script flow
- Identifying where errors occur exactly

**Behavior**:

```
+(/opt/wallabag/bin/console): /opt/wallabag/bin/console cache:warmup
+(/opt/wallabag/bin/console): env APP_ENV=prod /opt/wallabag/bin/console cache:warmup
+(/opt/wallabag/bin/console): [[ -d /opt/wallabag/app/cache ]]
+(/opt/wallabag/bin/console): rm -rf /opt/wallabag/app/cache/*
```

**⚠️ Warning**: Exposes passwords and secrets in log output! Only use in isolated environments.

**Log Output**: All trace output saved to logs (see `logs` mode)

**Combined with**: `keep`, `pause`, `logs`

---

### 4. **pause** - Step-by-Step Execution

Pauses after each major step (`msg_info`). Requires manual Enter press to continue.

**Use Case**:

- Inspect container state between steps
- Understand what each step does
- Identify which step causes problems

**Behavior**:

```
⏳ Setting up Container OS
[PAUSE] Press Enter to continue...
⏳ Updating Container OS
[PAUSE] Press Enter to continue...
⏳ Installing Dependencies
[PAUSE] Press Enter to continue...
```

**Between pauses**: You can open another terminal and inspect the container

```bash
# In another terminal while paused
pct enter 107
root@container:~# df -h  # Check disk usage
root@container:~# ps aux # Check running processes
```

**Combined with**: `motd`, `keep`, `logs`

---

### 5. **breakpoint** - Interactive Shell on Error

Opens interactive shell inside the container when an error occurs instead of cleanup prompt.

**Use Case**:

- Live debugging in the actual container
- Manual command testing
- Inspect container state at point of failure

**Behavior**:

```
✖ Installation failed in container 107 (exit code: 1)
✔ Container creation log: /tmp/create-lxc-107-abc12345.log
✔ Installation log: /tmp/install-lxc-107-abc12345.log

🐛 [DEV] Breakpoint mode - opening shell in container 107
Type 'exit' to return to host
root@wallabag:~#

# Now you can debug:
root@wallabag:~# tail -f /root/.install-abc12345.log
root@wallabag:~# mysql -u root -p$PASSWORD wallabag
root@wallabag:~# apt-get install -y strace
root@wallabag:~# exit

Container 107 still running. Remove now? (y/N): n
🔧 Container 107 kept for debugging
```

**Combined with**: `keep`, `logs`, `trace`

---

### 6. **logs** - Persistent Logging

Saves all logs to `/var/log/community-scripts/` with timestamps. Logs persist even on successful installation.

**Use Case**:

- Post-mortem analysis
- Performance analysis
- Automated testing with log collection
- CI/CD integration

**Behavior**:

```
Logs location: /var/log/community-scripts/

create-lxc-abc12345-20251117_143022.log    (host-side creation)
install-abc12345-20251117_143022.log       (container-side installation)
```

**Access logs**:

```bash
# View creation log
tail -f /var/log/community-scripts/create-lxc-*.log

# Search for errors
grep ERROR /var/log/community-scripts/*.log

# Analyze performance
grep "msg_info\|msg_ok" /var/log/community-scripts/create-*.log
```

**With trace mode**: Creates detailed trace of all commands

```bash
grep "^+" /var/log/community-scripts/install-*.log
```

**Combined with**: All other modes (recommended for CI/CD)

---

### 7. **dryrun** - Simulation Mode

Shows all commands that would be executed without actually running them.

**Use Case**:

- Test script logic without making changes
- Verify command syntax
- Understand what will happen
- Pre-flight checks

**Behavior**:

```
[DRYRUN] apt-get update
[DRYRUN] apt-get install -y curl
[DRYRUN] mkdir -p /opt/wallabag
[DRYRUN] cd /opt/wallabag
[DRYRUN] git clone https://github.com/wallabag/wallabag.git .
```

**No actual changes made**: Container/system remains unchanged

**Combined with**: `trace` (shows dryrun trace), `logs` (shows what would run)

---

## Mode Combinations

### Development Workflow

```bash
# First test: See what would happen
export dev_mode="dryrun,logs"
bash -c "$(curl ...)"

# Then test with tracing and pauses
export dev_mode="pause,trace,logs"
bash -c "$(curl ...)"

# Finally full debug with early SSH access
export dev_mode="motd,keep,breakpoint,logs"
bash -c "$(curl ...)"
```

### CI/CD Integration

```bash
# Automated testing with full logging
export dev_mode="logs"
export var_verbose="yes"
bash -c "$(curl ...)"

# Capture logs for analysis
tar czf installation-logs-$(date +%s).tar.gz /var/log/community-scripts/
```

### Production-like Testing

```bash
# Keep containers for manual verification
export dev_mode="keep,logs"
for i in {1..5}; do
  bash -c "$(curl ...)"
done

# Inspect all created containers
pct list
pct enter 100
```

### Live Debugging

```bash
# SSH in early, step through installation, debug on error
export dev_mode="motd,pause,breakpoint,keep"
bash -c "$(curl ...)"
```

---

## Environment Variables Reference

### Dev Mode Variables

- `dev_mode` (string): Comma-separated list of modes
  - Format: `"motd,keep,trace"`
  - Default: Empty (no dev modes)

### Output Control

- `var_verbose="yes"`: Show all command output (disables silent mode)
  - Pairs well with: `trace`, `pause`, `logs`

### Examples with vars

```bash
# Maximum verbosity and debugging
export var_verbose="yes"
export dev_mode="motd,trace,pause,logs"
bash -c "$(curl ...)"

# Silent debug (logs only)
export dev_mode="keep,logs"
bash -c "$(curl ...)"

# Interactive debugging
export var_verbose="yes"
export dev_mode="motd,breakpoint"
bash -c "$(curl ...)"
```

---

## Troubleshooting with Dev Mode

### "Installation failed at step X"

```bash
export dev_mode="pause,logs"
# Step through until the failure point
# Check container state between pauses
pct enter 107
```

### "Password/credentials not working"

```bash
export dev_mode="motd,keep,trace"
# With trace mode, see exact password handling (be careful with logs!)
# Use motd to SSH in and test manually
ssh root@container-ip
```

### "Permission denied errors"

```bash
export dev_mode="breakpoint,keep"
# Get shell at failure point
# Check file permissions, user context, SELinux status
ls -la /path/to/file
whoami
```

### "Networking issues"

```bash
export dev_mode="motd"
# SSH in with motd mode before main install
ssh root@container-ip
ping 8.8.8.8
nslookup example.com
```

### "Need to manually complete installation"

```bash
export dev_mode="motd,keep"
# Container accessible via SSH while installation runs
# After failure, SSH in and manually continue
ssh root@container-ip
# ... manual commands ...
exit
# Then use 'keep' mode to preserve container for inspection
```

---

## Log Files Locations

### Default (without `logs` mode)

- Host creation: `/tmp/create-lxc-<SESSION_ID>.log`
- Container install: Copied to `/tmp/install-lxc-<CTID>-<SESSION_ID>.log` on failure

### With `logs` mode

- Host creation: `/var/log/community-scripts/create-lxc-<SESSION_ID>-<TIMESTAMP>.log`
- Container install: `/var/log/community-scripts/install-<SESSION_ID>-<TIMESTAMP>.log`

### View logs

```bash
# Tail in real-time
tail -f /var/log/community-scripts/*.log

# Search for errors
grep -r "exit code [1-9]" /var/log/community-scripts/

# Filter by session
grep "ed563b19" /var/log/community-scripts/*.log
```

---

## Best Practices

### ✅ DO

- Use `logs` mode for CI/CD and automated testing
- Use `motd` for early SSH access during long installations
- Use `pause` when learning the installation flow
- Use `trace` when debugging logic issues (watch for secrets!)
- Combine modes for comprehensive debugging
- Archive logs after successful tests

### ❌ DON'T

- Use `trace` in production or with untrusted networks (exposes secrets)
- Leave `keep` mode enabled for unattended scripts (containers accumulate)
- Use `dryrun` and expect actual changes
- Commit `dev_mode` exports to production deployment scripts
- Use `breakpoint` in non-interactive environments (will hang)

---

## Examples

### Example 1: Debug a Failed Installation

```bash
# Initial test to see the failure
export dev_mode="keep,logs"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/wallabag.sh)"

# Container 107 kept, check logs
tail /var/log/community-scripts/install-*.log

# SSH in to debug
pct enter 107
root@wallabag:~# cat /root/.install-*.log | tail -100
root@wallabag:~# apt-get update  # Retry the failing command
root@wallabag:~# exit

# Re-run with manual step-through
export dev_mode="motd,pause,keep"
bash -c "$(curl ...)"
```

### Example 2: Verify Installation Steps

```bash
export dev_mode="pause,logs"
export var_verbose="yes"
bash -c "$(curl ...)"

# Press Enter through each step
# Monitor container in another terminal
# pct enter 107
# Review logs in real-time
```

### Example 3: CI/CD Pipeline Integration

```bash
#!/bin/bash
export dev_mode="logs"
export var_verbose="no"

for app in wallabag nextcloud wordpress; do
  echo "Testing $app installation..."
  APP="$app" bash -c "$(curl ...)" || {
    echo "FAILED: $app"
    tar czf logs-$app.tar.gz /var/log/community-scripts/
    exit 1
  }
  echo "SUCCESS: $app"
done

echo "All installations successful"
tar czf all-logs.tar.gz /var/log/community-scripts/
```

---

## Advanced Usage

### Custom Log Analysis

```bash
# Extract all errors
grep "ERROR\|exit code [1-9]" /var/log/community-scripts/*.log

# Performance timeline
grep "^$(date +%Y-%m-%d)" /var/log/community-scripts/*.log | grep "msg_"

# Memory usage during install
grep "free\|available" /var/log/community-scripts/*.log
```

### Integration with External Tools

```bash
# Send logs to Elasticsearch
curl -X POST "localhost:9200/installation-logs/_doc" \
  -H 'Content-Type: application/json' \
  -d @/var/log/community-scripts/install-*.log

# Archive for compliance
tar czf installation-records-$(date +%Y%m).tar.gz \
  /var/log/community-scripts/
gpg --encrypt installation-records-*.tar.gz
```

---

## Support & Issues

When reporting installation issues, always include:

```bash
# Collect all relevant information
export dev_mode="logs"
# Run the failing installation
# Then provide:
tar czf debug-logs.tar.gz /var/log/community-scripts/
```

Include the `debug-logs.tar.gz` when reporting issues for better diagnostics.
