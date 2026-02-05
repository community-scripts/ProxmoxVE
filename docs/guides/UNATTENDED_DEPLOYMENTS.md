# Unattended Deployments Guide

Complete guide for automated, zero-interaction container deployments using community-scripts for Proxmox VE.

---

## 🎯 What You'll Learn

This comprehensive guide covers:
- ✅ Complete automation of container deployments
- ✅ Zero-interaction installations
- ✅ Batch deployments (multiple containers)
- ✅ Infrastructure as Code (Ansible, Terraform)
- ✅ CI/CD pipeline integration
- ✅ Error handling and rollback strategies
- ✅ Production-ready deployment scripts
- ✅ Security best practices

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Deployment Methods](#deployment-methods)
4. [Single Container Deployment](#single-container-deployment)
5. [Batch Deployments](#batch-deployments)
6. [Infrastructure as Code](#infrastructure-as-code)
7. [CI/CD Integration](#cicd-integration)
8. [Error Handling](#error-handling)
9. [Security Considerations](#security-considerations)

---

## Overview

Unattended deployments allow you to:
- ✅ Deploy containers without manual interaction
- ✅ Automate infrastructure provisioning
- ✅ Integrate with CI/CD pipelines
- ✅ Maintain consistent configurations
- ✅ Scale deployments across multiple nodes

---

## Prerequisites

### 1. Proxmox VE Access
```bash
# Verify you have root access
whoami  # Should return: root

# Check Proxmox version (8.0+ or 9.0-9.1 required)
pveversion
```

### 2. Network Connectivity
```bash
# Test GitHub access
curl -I https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh

# Test internet connectivity
ping -c 1 1.1.1.1
```

### 3. Storage Available
```bash
# List available storage
pvesm status

# Check free space
df -h
```

---

## Deployment Methods

### Method Comparison

| Method | Use Case | Complexity | Flexibility |
|--------|----------|------------|-------------|
| **Environment Variables** | Quick one-offs | Low | High |
| **App Defaults** | Repeat deployments | Low | Medium |
| **Shell Scripts** | Batch operations | Medium | High |
| **Ansible** | Infrastructure as Code | High | Very High |
| **Terraform** | Cloud-native IaC | High | Very High |

---

## Single Container Deployment

### Basic Unattended Deployment

**Simplest form:**
```bash
var_hostname=myserver bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"
```

### Complete Configuration Example

```bash
#!/bin/bash
# deploy-single.sh - Deploy a single container with full configuration

var_unprivileged=1 \
var_cpu=4 \
var_ram=4096 \
var_disk=30 \
var_hostname=production-app \
var_os=debian \
var_version=13 \
var_brg=vmbr0 \
var_net=dhcp \
var_ipv6_method=none \
var_ssh=yes \
var_ssh_authorized_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... admin@workstation" \
var_nesting=1 \
var_tags=production,automated \
var_protection=yes \
var_verbose=no \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"

echo "✓ Container deployed successfully"
```

### Using IP Range Scan for Automatic IP Assignment

Instead of manually specifying static IPs, you can define an IP range. The system will automatically ping each IP and assign the first free one:

```bash
#!/bin/bash
# deploy-with-ip-scan.sh - Auto-assign first free IP from range

var_unprivileged=1 \
var_cpu=4 \
var_ram=4096 \
var_hostname=web-server \
var_net=192.168.1.100/24-192.168.1.150/24 \
var_gateway=192.168.1.1 \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"

# The script will:
# 1. Ping 192.168.1.100 - if responds, skip
# 2. Ping 192.168.1.101 - if responds, skip
# 3. Continue until first IP that doesn't respond
# 4. Assign that IP to the container
```

> **Note**: IP range format is `START_IP/CIDR-END_IP/CIDR`. Both sides must include the same CIDR notation.

### Using App Defaults

**Step 1: Create defaults once (interactive)**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/pihole.sh)"
# Select "Advanced Settings" → Configure → Save as "App Defaults"
```

**Step 2: Deploy unattended (uses saved defaults)**
```bash
#!/bin/bash
# deploy-with-defaults.sh

# App defaults are loaded automatically
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/pihole.sh)"
# Script will use /usr/local/community-scripts/defaults/pihole.vars
```

### Advanced Configuration Variables

Beyond the basic resource settings, you can control advanced container features:

| Variable | Description | Options |
|----------|-------------|---------|
| `var_os` | Operating system template | `debian`, `ubuntu`, `alpine` |
| `var_version` | OS version | `12`, `13` (Debian), `22.04`, `24.04` (Ubuntu) |
| `var_gpu` | Enable GPU passthrough | `yes`, `no` (Default: `no`) |
| `var_tun` | Enable TUN/TAP device | `yes`, `no` (Default: `no`) |
| `var_nesting` | Enable nesting | `1`, `0` (Default: `1`) |

**Example with GPU and TUN:**
```bash
var_gpu=yes \
var_tun=yes \
var_hostname=transcoder \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/plex.sh)"
```

---

## Batch Deployments

### Deploy Multiple Containers

#### Simple Loop

```bash
#!/bin/bash
# batch-deploy-simple.sh

apps=("thingsboard" "qui" "flatnotes")

for app in "${apps[@]}"; do
  echo "Deploying $app..."
  var_hostname="$app-server" \
  var_cpu=2 \
  var_ram=2048 \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${app}.sh)"

  echo "✓ $app deployed"
  sleep 5  # Wait between deployments
done
```

#### Advanced with Configuration Array

```bash
#!/bin/bash
# batch-deploy-advanced.sh - Deploy multiple containers with individual configs

declare -A CONTAINERS=(
  ["beszel"]="1:512:8:vmbr0:monitoring"
  ["qui"]="2:1024:10:vmbr0:torrent,ui"
  ["thingsboard"]="6:8192:50:vmbr1:iot,industrial"
  ["dockge"]="2:2048:10:vmbr0:docker,management"
)

for app in "${!CONTAINERS[@]}"; do
  # Parse configuration
  IFS=':' read -r cpu ram disk bridge tags <<< "${CONTAINERS[$app]}"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Deploying: $app"
  echo "  CPU: $cpu cores"
  echo "  RAM: $ram MB"
  echo "  Disk: $disk GB"
  echo "  Bridge: $bridge"
  echo "  Tags: $tags"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Deploy container
  var_unprivileged=1 \
  var_cpu="$cpu" \
  var_ram="$ram" \
  var_disk="$disk" \
  var_hostname="$app" \
  var_brg="$bridge" \
  var_net=dhcp \
  var_ipv6_method=none \
  var_ssh=yes \
  var_tags="$tags,automated" \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${app}.sh)" 2>&1 | tee "deploy-${app}.log"

  if [ $? -eq 0 ]; then
    echo "✓ $app deployed successfully"
  else
    echo "✗ $app deployment failed - check deploy-${app}.log"
  fi

  sleep 5
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Batch deployment complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

#### Parallel Deployment

```bash
#!/bin/bash
# parallel-deploy.sh - Deploy multiple containers in parallel

deploy_container() {
  local app="$1"
  local cpu="$2"
  local ram="$3"
  local disk="$4"

  echo "[$app] Starting deployment..."
  var_cpu="$cpu" \
  var_ram="$ram" \
  var_disk="$disk" \
  var_hostname="$app" \
  var_net=dhcp \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${app}.sh)" \
    &> "deploy-${app}.log"

  echo "[$app] ✓ Completed"
}

# Export function for parallel execution
export -f deploy_container

# Deploy in parallel (max 3 at a time)
parallel -j 3 deploy_container ::: \
  "debian 2 2048 10" \
  "ubuntu 2 2048 10" \
  "alpine 1 1024 5" \
  "pihole 2 1024 8" \
  "docker 4 4096 30"

echo "All deployments complete!"
```

---

## Infrastructure as Code

### Ansible Playbook

#### Basic Playbook

```yaml
---
# playbook-proxmox.yml
- name: Deploy ProxmoxVE Containers
  hosts: proxmox_hosts
  become: yes
  tasks:
    - name: Deploy Debian Container
      shell: |
        var_unprivileged=1 \
        var_cpu=2 \
        var_ram=2048 \
        var_disk=10 \
        var_hostname=debian-{{ inventory_hostname }} \
        var_net=dhcp \
        var_ssh=yes \
        var_tags=ansible,automated \
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"
      args:
        executable: /bin/bash
      register: deploy_result

    - name: Display deployment result
      debug:
        var: deploy_result.stdout_lines
```

#### Advanced Playbook with Variables

```yaml
---
# advanced-playbook.yml
- name: Deploy Multiple Container Types
  hosts: proxmox
  vars:
    containers:
      - name: pihole
        cpu: 2
        ram: 1024
        disk: 8
        tags: "dns,network"
      - name: homeassistant
        cpu: 4
        ram: 4096
        disk: 20
        tags: "automation,ha"
      - name: docker
        cpu: 6
        ram: 8192
        disk: 50
        tags: "containers,docker"

    ssh_key: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"

  tasks:
    - name: Ensure community-scripts directory exists
      file:
        path: /usr/local/community-scripts/defaults
        state: directory
        mode: '0755'

    - name: Deploy containers
      shell: |
        var_unprivileged=1 \
        var_cpu={{ item.cpu }} \
        var_ram={{ item.ram }} \
        var_disk={{ item.disk }} \
        var_hostname={{ item.name }} \
        var_brg=vmbr0 \
        var_net=dhcp \
        var_ipv6_method=none \
        var_ssh=yes \
        var_ssh_authorized_key="{{ ssh_key }}" \
        var_tags="{{ item.tags }},ansible" \
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/{{ item.name }}.sh)"
      args:
        executable: /bin/bash
      loop: "{{ containers }}"
      register: deployment_results

    - name: Wait for containers to be ready
      wait_for:
        timeout: 60

    - name: Report deployment status
      debug:
        msg: "Deployed {{ item.item.name }} - Status: {{ 'Success' if item.rc == 0 else 'Failed' }}"
      loop: "{{ deployment_results.results }}"
```

Run with:
```bash
ansible-playbook -i inventory.ini advanced-playbook.yml
```

### Terraform Integration

```hcl
# main.tf - Deploy containers via Terraform

terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://proxmox.example.com:8006/api2/json"
  pm_api_token_id = "terraform@pam!terraform"
  pm_api_token_secret = var.proxmox_token
}

resource "null_resource" "deploy_container" {
  for_each = var.containers

  provisioner "remote-exec" {
    inline = [
      "var_unprivileged=1",
      "var_cpu=${each.value.cpu}",
      "var_ram=${each.value.ram}",
      "var_disk=${each.value.disk}",
      "var_hostname=${each.key}",
      "var_net=dhcp",
      "bash -c \"$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${each.value.template}.sh)\""
    ]

    connection {
      type = "ssh"
      host = var.proxmox_host
      user = "root"
      private_key = file("~/.ssh/id_rsa")
    }
  }
}

variable "containers" {
  type = map(object({
    template = string
    cpu = number
    ram = number
    disk = number
  }))

  default = {
    "pihole" = {
      template = "pihole"
      cpu = 2
      ram = 1024
      disk = 8
    }
    "homeassistant" = {
      template = "homeassistant"
      cpu = 4
      ram = 4096
      disk = 20
    }
  }
}
```

---

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/deploy-container.yml
name: Deploy Container to Proxmox

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      container_type:
        description: 'Container type to deploy'
        required: true
        type: choice
        options:
          - debian
          - ubuntu
          - docker
          - pihole

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Proxmox
        uses: appleboy/ssh-action@v0.1.10
        with:
          host: ${{ secrets.PROXMOX_HOST }}
          username: root
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            var_unprivileged=1 \
            var_cpu=4 \
            var_ram=4096 \
            var_disk=30 \
            var_hostname=${{ github.event.inputs.container_type }}-ci \
            var_net=dhcp \
            var_ssh=yes \
            var_tags=ci-cd,automated \
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${{ github.event.inputs.container_type }}.sh)"

      - name: Notify deployment status
        if: success()
        run: echo "✓ Container deployed successfully"
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - deploy

deploy_container:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client curl bash
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
    - ssh-keyscan $PROXMOX_HOST >> ~/.ssh/known_hosts
  script:
    - |
      ssh root@$PROXMOX_HOST << 'EOF'
        var_unprivileged=1 \
        var_cpu=4 \
        var_ram=4096 \
        var_disk=30 \
        var_hostname=gitlab-ci-container \
        var_net=dhcp \
        var_tags=gitlab-ci,automated \
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"
      EOF
  only:
    - main
  when: manual
```

---

## Error Handling

### Deployment Verification Script

```bash
#!/bin/bash
# deploy-with-verification.sh

APP="debian"
HOSTNAME="production-server"
MAX_RETRIES=3
RETRY_COUNT=0

deploy_container() {
  echo "Attempting deployment (Try $((RETRY_COUNT + 1))/$MAX_RETRIES)..."

  var_unprivileged=1 \
  var_cpu=4 \
  var_ram=4096 \
  var_disk=30 \
  var_hostname="$HOSTNAME" \
  var_net=dhcp \
  var_ssh=yes \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${APP}.sh)" 2>&1 | tee deploy.log

  return ${PIPESTATUS[0]}
}

verify_deployment() {
  echo "Verifying deployment..."

  # Check if container exists
  if ! pct list | grep -q "$HOSTNAME"; then
    echo "✗ Container not found in pct list"
    return 1
  fi

  # Check if container is running
  CTID=$(pct list | grep "$HOSTNAME" | awk '{print $1}')
  STATUS=$(pct status "$CTID" | awk '{print $2}')

  if [ "$STATUS" != "running" ]; then
    echo "✗ Container not running (Status: $STATUS)"
    return 1
  fi

  # Check network connectivity
  if ! pct exec "$CTID" -- ping -c 1 1.1.1.1 &>/dev/null; then
    echo "⚠ Warning: No internet connectivity"
  fi

  echo "✓ Deployment verified successfully"
  echo "  Container ID: $CTID"
  echo "  Status: $STATUS"
  echo "  IP: $(pct exec "$CTID" -- hostname -I)"

  return 0
}

# Main deployment loop with retry
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if deploy_container; then
    if verify_deployment; then
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "✓ Deployment successful!"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      exit 0
    else
      echo "✗ Deployment verification failed"
    fi
  else
    echo "✗ Deployment failed"
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))

  if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
    echo "Retrying in 10 seconds..."
    sleep 10
  fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✗ Deployment failed after $MAX_RETRIES attempts"
echo "Check deploy.log for details"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exit 1
```

### Rollback on Failure

```bash
#!/bin/bash
# deploy-with-rollback.sh

APP="debian"
HOSTNAME="test-server"
SNAPSHOT_NAME="pre-deployment"

# Take snapshot of existing container (if exists)
backup_existing() {
  EXISTING_CTID=$(pct list | grep "$HOSTNAME" | awk '{print $1}')
  if [ -n "$EXISTING_CTID" ]; then
    echo "Creating snapshot of existing container..."
    pct snapshot "$EXISTING_CTID" "$SNAPSHOT_NAME" --description "Pre-deployment backup"
    return 0
  fi
  return 1
}

# Deploy new container
deploy() {
  var_hostname="$HOSTNAME" \
  var_cpu=4 \
  var_ram=4096 \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${APP}.sh)"
  return $?
}

# Rollback to snapshot
rollback() {
  local ctid="$1"
  echo "Rolling back to snapshot..."
  pct rollback "$ctid" "$SNAPSHOT_NAME"
  pct delsnapshot "$ctid" "$SNAPSHOT_NAME"
}

# Main execution
backup_existing
HAD_BACKUP=$?

if deploy; then
  echo "✓ Deployment successful"
  [ $HAD_BACKUP -eq 0 ] && echo "You can remove the snapshot with: pct delsnapshot <CTID> $SNAPSHOT_NAME"
else
  echo "✗ Deployment failed"
  if [ $HAD_BACKUP -eq 0 ]; then
    read -p "Rollback to previous version? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rollback "$EXISTING_CTID"
      echo "✓ Rolled back successfully"
    fi
  fi
  exit 1
fi
```

---

## Security Considerations

### Secure Deployment Script

```bash
#!/bin/bash
# secure-deploy.sh - Production-ready secure deployment

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
readonly APP="debian"
readonly HOSTNAME="secure-server"
readonly SSH_KEY_PATH="/root/.ssh/id_rsa.pub"
readonly LOG_FILE="/var/log/container-deployments.log"

# Logging function
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Validate prerequisites
validate_environment() {
  log "Validating environment..."

  # Check if running as root
  if [ "$EUID" -ne 0 ]; then
    log "ERROR: Must run as root"
    exit 1
  fi

  # Check SSH key exists
  if [ ! -f "$SSH_KEY_PATH" ]; then
    log "ERROR: SSH key not found at $SSH_KEY_PATH"
    exit 1
  fi

  # Check internet connectivity
  if ! curl -s --max-time 5 https://github.com &>/dev/null; then
    log "ERROR: No internet connectivity"
    exit 1
  fi

  log "✓ Environment validated"
}

# Secure deployment
deploy_secure() {
  log "Starting secure deployment for $HOSTNAME..."

  SSH_KEY=$(cat "$SSH_KEY_PATH")

  var_unprivileged=1 \
  var_cpu=4 \
  var_ram=4096 \
  var_disk=30 \
  var_hostname="$HOSTNAME" \
  var_brg=vmbr0 \
  var_net=dhcp \
  var_ipv6_method=disable \
  var_ssh=yes \
  var_ssh_authorized_key="$SSH_KEY" \
  var_nesting=0 \
  var_keyctl=0 \
  var_fuse=0 \
  var_protection=yes \
  var_tags=production,secure,automated \
  var_verbose=no \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${APP}.sh)" 2>&1 | tee -a "$LOG_FILE"

  if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log "✓ Deployment successful"
    return 0
  else
    log "✗ Deployment failed"
    return 1
  fi
}

# Main execution
main() {
  validate_environment

  if deploy_secure; then
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Secure deployment completed successfully"
    log "Container: $HOSTNAME"
    log "Features: Unprivileged, SSH-only, Protected"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
  else
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Deployment failed - check logs at $LOG_FILE"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
  fi
}

main "$@"
```

### SSH Key Management

```bash
#!/bin/bash
# deploy-with-ssh-keys.sh - Secure SSH key deployment

# Load SSH keys from multiple sources
load_ssh_keys() {
  local keys=()

  # Personal key
  if [ -f ~/.ssh/id_rsa.pub ]; then
    keys+=("$(cat ~/.ssh/id_rsa.pub)")
  fi

  # Team keys
  if [ -f /etc/ssh/authorized_keys.d/team ]; then
    while IFS= read -r key; do
      [ -n "$key" ] && keys+=("$key")
    done < /etc/ssh/authorized_keys.d/team
  fi

  # Join keys with newline
  printf "%s\n" "${keys[@]}"
}

# Deploy with multiple SSH keys
SSH_KEYS=$(load_ssh_keys)

var_ssh=yes \
var_ssh_authorized_key="$SSH_KEYS" \
var_hostname=multi-key-server \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"
```

---

## Complete Production Example

```bash
#!/bin/bash
# production-deploy.sh - Complete production deployment system

set -euo pipefail

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Configuration
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="/var/log/proxmox-deployments"
readonly CONFIG_FILE="$SCRIPT_DIR/deployment-config.json"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

setup_logging() {
  mkdir -p "$LOG_DIR"
  exec 1> >(tee -a "$LOG_DIR/deployment-$(date +%Y%m%d-%H%M%S).log")
  exec 2>&1
}

log_info() { echo "[INFO] $(date +'%H:%M:%S') - $*"; }
log_error() { echo "[ERROR] $(date +'%H:%M:%S') - $*" >&2; }
log_success() { echo "[SUCCESS] $(date +'%H:%M:%S') - $*"; }

validate_prerequisites() {
  log_info "Validating prerequisites..."

  [ "$EUID" -eq 0 ] || { log_error "Must run as root"; exit 1; }
  command -v jq >/dev/null 2>&1 || { log_error "jq not installed"; exit 1; }
  command -v curl >/dev/null 2>&1 || { log_error "curl not installed"; exit 1; }

  log_success "Prerequisites validated"
}

deploy_from_config() {
  local config_file="$1"

  if [ ! -f "$config_file" ]; then
    log_error "Config file not found: $config_file"
    return 1
  fi

  local container_count
  container_count=$(jq '.containers | length' "$config_file")

  log_info "Deploying $container_count containers from config..."

  for i in $(seq 0 $((container_count - 1))); do
    local name cpu ram disk app tags

    name=$(jq -r ".containers[$i].name" "$config_file")
    cpu=$(jq -r ".containers[$i].cpu" "$config_file")
    ram=$(jq -r ".containers[$i].ram" "$config_file")
    disk=$(jq -r ".containers[$i].disk" "$config_file")
    app=$(jq -r ".containers[$i].app" "$config_file")
    tags=$(jq -r ".containers[$i].tags" "$config_file")

    log_info "Deploying container: $name ($app)"

    var_unprivileged=1 \
    var_cpu="$cpu" \
    var_ram="$ram" \
    var_disk="$disk" \
    var_hostname="$name" \
    var_net=dhcp \
    var_ssh=yes \
    var_tags="$tags,automated" \
    var_protection=yes \
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${app}.sh)"

    if [ $? -eq 0 ]; then
      log_success "Deployed: $name"
    else
      log_error "Failed to deploy: $name"
    fi

    sleep 5
  done
}

generate_report() {
  log_info "Generating deployment report..."

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "DEPLOYMENT REPORT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Time: $(date)"
  echo ""
  pct list
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
  setup_logging
  log_info "Starting production deployment system"

  validate_prerequisites
  deploy_from_config "$CONFIG_FILE"
  generate_report

  log_success "Production deployment complete"
}

main "$@"
```

**Example config file (deployment-config.json):**
```json
{
  "containers": [
    {
      "name": "pihole",
      "app": "pihole",
      "cpu": 2,
      "ram": 1024,
      "disk": 8,
      "tags": "dns,network,production"
    },
    {
      "name": "homeassistant",
      "app": "homeassistant",
      "cpu": 4,
      "ram": 4096,
      "disk": 20,
      "tags": "automation,ha,production"
    },
    {
      "name": "docker-host",
      "app": "docker",
      "cpu": 8,
      "ram": 16384,
      "disk": 100,
      "tags": "containers,docker,production"
    }
  ]
}
```

---

## See Also

- [Defaults System Guide](DEFAULTS_GUIDE.md)
- [Configuration Reference](CONFIGURATION_REFERENCE.md)
- [Security Best Practices](SECURITY_GUIDE.md)
- [Network Configuration](NETWORK_GUIDE.md)
