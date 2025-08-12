#!/usr/bin/env bash

# Copyright (c) 2023 community-scripts ORG
# This script is designed to install the Proxmox Dependency Check Hookscript.
# It sets up a dependency-checking hookscript and automates its
# application to all new and existing guests using a systemd watcher.
# License: MIT

function header_info {
  clear
  cat <<"EOF"
  ____                            _                        ____ _               _    
 |  _ \  ___ _ __   ___ _ __   __| | ___ _ __   ___ _   _ / ___| |__   ___  ___| | __
 | | | |/ _ \ '_ \ / _ \ '_ \ / _` |/ _ \ '_ \ / __| | | | |   | '_ \ / _ \/ __| |/ /
 | |_| |  __/ |_) |  __/ | | | (_| |  __/ | | | (__| |_| | |___| | | |  __/ (__|   < 
 |____/ \___| .__/ \___|_| |_|\__,_|\___|_| |_|\___|\__, |\____|_| |_|\___|\___|_|\_\
            |_|                                     |___/                            
EOF
}

# Color variables
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
RD=$(echo "\033[01;31m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD=" "
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

# Spinner for progress indication (simplified)
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Message functions
msg_info() {
  echo -ne " ${YW}›${CL}  $1..."
}

msg_ok() {
  echo -e "${BFR} ${CM}  $1${CL}"
}

msg_error() {
  echo -e "${BFR} ${CROSS}  $1${CL}"
}
# --- End of base script functions ---


# --- Installation Functions ---

# Function to create the actual hookscript that runs before guest startup
create_dependency_hookscript() {
    msg_info "Creating dependency-check hookscript"
    mkdir -p /var/lib/vz/snippets
    cat <<'EOF' > /var/lib/vz/snippets/dependency-check.sh
#!/bin/bash
# Proxmox Hookscript for Pre-Start Dependency Checking
# Works for both QEMU VMs and LXC Containers

# --- Configuration ---
POLL_INTERVAL=5       # Seconds to wait between checks
MAX_ATTEMPTS=60       # Max number of attempts before failing (60 * 5s = 5 minutes)
# --- End Configuration ---

VMID=$1
PHASE=$2

# Function for logging to syslog with a consistent format
log() {
    echo "[hookscript-dep-check] VMID $VMID: $1"
}

# This script only runs in the 'pre-start' phase
if [ "$PHASE" != "pre-start" ]; then
    exit 0
fi

log "--- Starting Pre-Start Dependency Check ---"

# --- Determine Guest Type (QEMU or LXC) ---
GUEST_TYPE=""
CONFIG_CMD=""
if qm config "$VMID" >/dev/null 2>&1; then
    GUEST_TYPE="qemu"
    CONFIG_CMD="qm config"
    log "Guest type is QEMU (VM)."
elif pct config "$VMID" >/dev/null 2>&1; then
    GUEST_TYPE="lxc"
    CONFIG_CMD="pct config"
    log "Guest type is LXC (Container)."
else
    log "ERROR: Could not determine guest type for $VMID. Aborting."
    exit 1
fi

GUEST_CONFIG=$($CONFIG_CMD "$VMID")

# --- 1. Storage Availability Check ---
log "Checking storage availability..."
# Grep for all disk definitions (scsi, sata, virtio, ide, rootfs, mp)
# and extract the storage identifier (the field between the colons).
# Sort -u gets the unique list of storage pools.
STORAGE_IDS=$(echo "$GUEST_CONFIG" | grep -E '^(scsi|sata|virtio|ide|rootfs|mp)[0-9]*:' | awk -F'[:]' '{print $2}' | awk '{print$1}' | sort -u)

if [ -z "$STORAGE_IDS" ]; then
    log "No storage dependencies found to check."
else
    for STORAGE_ID in $STORAGE_IDS; do
        log "Checking status of storage: '$STORAGE_ID'"
        ATTEMPTS=0
        while true; do
            # Grep for the storage ID line in pvesm status and check the 'Active' column (3rd column)
            STATUS=$(pvesm status | grep "^\s*$STORAGE_ID\s" | awk '{print $3}')
            if [ "$STATUS" == "active" ]; then
                log "Storage '$STORAGE_ID' is active."
                break
            fi

            ATTEMPTS=$((ATTEMPTS + 1))
            if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
                log "ERROR: Timeout waiting for storage '$STORAGE_ID' to become active. Aborting start."
                exit 1
            fi

            log "Storage '$STORAGE_ID' is not active (current status: '${STATUS:-inactive/unknown}'). Waiting ${POLL_INTERVAL}s... (Attempt ${ATTEMPTS}/${MAX_ATTEMPTS})"
            sleep $POLL_INTERVAL
        done
    done
fi
log "All storage dependencies are met."


# --- 2. Custom Tag-Based Dependency Check ---
log "Checking for custom tag-based dependencies..."
TAGS=$(echo "$GUEST_CONFIG" | grep '^tags:' | awk '{print $2}')

if [ -z "$TAGS" ]; then
    log "No tags found. Skipping custom dependency check."
else
    # Replace colons with spaces to loop through tags
    for TAG in ${TAGS//;/ }; do
        # Check if the tag matches our dependency format 'dep_*'
        if [[ $TAG == dep_* ]]; then
            log "Found dependency tag: '$TAG'"

            # Split tag into parts using underscore as delimiter
            IFS='_' read -ra PARTS <<< "$TAG"
            DEP_TYPE="${PARTS[1]}"

            ATTEMPTS=0
            while true; do
                CHECK_PASSED=false
                case "$DEP_TYPE" in
                    "tcp")
                        HOST="${PARTS[2]}"
                        PORT="${PARTS[3]}"
                        if [ -z "$HOST" ] || [ -z "$PORT" ]; then
                            log "ERROR: Malformed TCP dependency tag '$TAG'. Skipping."
                            CHECK_PASSED=true # Skip to avoid infinite loop
                        # nc -z is great for this. -w sets a timeout.
                        elif nc -z -w 2 "$HOST" "$PORT"; then
                            log "TCP dependency met: Host $HOST port $PORT is open."
                            CHECK_PASSED=true
                        fi
                        ;;

                    "ping")
                        HOST="${PARTS[2]}"
                        if [ -z "$HOST" ]; then
                            log "ERROR: Malformed PING dependency tag '$TAG'. Skipping."
                            CHECK_PASSED=true # Skip to avoid infinite loop
                        # ping -c 1 (one packet) -W 2 (2-second timeout)
                        elif ping -c 1 -W 2 "$HOST" >/dev/null 2>&1; then
                            log "Ping dependency met: Host $HOST is reachable."
                            CHECK_PASSED=true
                        fi
                        ;;

                    *)
                        log "WARNING: Unknown dependency type '$DEP_TYPE' in tag '$TAG'. Ignoring."
                        CHECK_PASSED=true # Mark as passed to avoid getting stuck
                        ;;
                esac

                if $CHECK_PASSED; then
                    break
                fi

                ATTEMPTS=$((ATTEMPTS + 1))
                if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
                    log "ERROR: Timeout waiting for dependency '$TAG'. Aborting start."
                    exit 1
                fi

                log "Dependency '$TAG' not met. Waiting ${POLL_INTERVAL}s... (Attempt ${ATTEMPTS}/${MAX_ATTEMPTS})"
                sleep $POLL_INTERVAL
            done
        fi
    done
fi

log "All custom dependencies are met."
log "--- Dependency Check Complete. Proceeding with start. ---"
exit 0
EOF
    chmod +x /var/lib/vz/snippets/dependency-check.sh
    msg_ok "Created dependency-check hookscript"
}

# Function to create the config file for exclusions
create_exclusion_config() {
    msg_info "Creating exclusion configuration file"
    if [ -f /etc/default/pve-auto-hook ]; then
        msg_ok "Exclusion file already exists, skipping."
    else
        cat <<'EOF' > /etc/default/pve-auto-hook
#
# Configuration for the Proxmox Automatic Hookscript Applicator
#
# Add VM or LXC IDs here to prevent the hookscript from being added.
# Separate IDs with spaces.
#
# Example:
# IGNORE_IDS="9000 9001 105"
#

IGNORE_IDS=""
EOF
        msg_ok "Created exclusion configuration file"
    fi
}

# Function to create the script that applies the hook
create_applicator_script() {
    msg_info "Creating the hookscript applicator script"
    cat <<'EOF' > /usr/local/bin/pve-apply-hookscript.sh
#!/bin/bash
HOOKSCRIPT_VOLUME_ID="local:snippets/dependency-check.sh"
CONFIG_FILE="/etc/default/pve-auto-hook"
LOG_TAG="pve-auto-hook-list"

log() {
    systemd-cat -t "$LOG_TAG" <<< "$1"
}

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Process QEMU VMs
qm list | awk 'NR>1 {print $1}' | while read -r VMID; do
    is_ignored=false
    for id_to_ignore in $IGNORE_IDS; do
        if [ "$id_to_ignore" == "$VMID" ]; then is_ignored=true; break; fi
    done
    if $is_ignored; then continue; fi
    if qm config "$VMID" | grep -q '^hookscript:'; then continue; fi
    log "Hookscript not found for VM $VMID. Applying..."
    qm set "$VMID" --hookscript "$HOOKSCRIPT_VOLUME_ID"
done

# Process LXC Containers
pct list | awk 'NR>1 {print $1}' | while read -r VMID; do
    is_ignored=false
    for id_to_ignore in $IGNORE_IDS; do
        if [ "$id_to_ignore" == "$VMID" ]; then is_ignored=true; break; fi
    done
    if $is_ignored; then continue; fi
    if pct config "$VMID" | grep -q '^hookscript:'; then continue; fi
    log "Hookscript not found for LXC $VMID. Applying..."
    pct set "$VMID" --hookscript "$HOOKSCRIPT_VOLUME_ID"
done
EOF
    chmod +x /usr/local/bin/pve-apply-hookscript.sh
    msg_ok "Created applicator script"
}

# Function to set up the systemd watcher and service
create_systemd_units() {
    msg_info "Creating systemd watcher and service units"
    cat <<'EOF' > /etc/systemd/system/pve-auto-hook.path
[Unit]
Description=Watch for new Proxmox guest configs to apply hookscript

[Path]
PathModified=/etc/pve/qemu-server/
PathModified=/etc/pve/lxc/

[Install]
WantedBy=multi-user.target
EOF

    cat <<'EOF' > /etc/systemd/system/pve-auto-hook.service
[Unit]
Description=Automatically add hookscript to new Proxmox guests

[Service]
Type=oneshot
ExecStart=/usr/local/bin/pve-apply-hookscript.sh
EOF
    msg_ok "Created systemd units"
}


# --- Main Execution ---
header_info

if ! command -v pveversion >/dev/null 2>&1; then
    msg_error "This script must be run on a Proxmox VE host."
    exit 1
fi

echo -e "\nThis script will install a service to automatically apply a"
echo -e "dependency-checking hookscript to all new and existing Proxmox guests."
echo -e "${YW}This includes creating files in:${CL}"
echo -e "  - /var/lib/vz/snippets/"
echo -e "  - /usr/local/bin/"
echo -e "  - /etc/default/"
echo -e "  - /etc/systemd/system/\n"

read -p "Do you want to proceed with the installation? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    msg_error "Installation cancelled."
    exit 1
fi

echo -e "\n"
create_dependency_hookscript
create_exclusion_config
create_applicator_script
create_systemd_units

msg_info "Reloading systemd and enabling the watcher"
(systemctl daemon-reload && systemctl enable --now pve-auto-hook.path) >/dev/null 2>&1 &
spinner
msg_ok "Systemd watcher enabled and running"

msg_info "Performing initial run to update existing guests"
/usr/local/bin/pve-apply-hookscript.sh >/dev/null 2>&1 &
spinner
msg_ok "Initial run complete"

echo -e "\n\n${GN}Installation successful!${CL}"
echo -e "The service is now active and will monitor for new guests."
echo -e "To ${YW}exclude${CL} a VM or LXC, add its ID to the ${YW}IGNORE_IDS${CL} variable in:"
echo -e "  ${YW}/etc/default/pve-auto-hook${CL}"
echo -e "\nYou can monitor the service's activity with:"
echo -e "  ${YW}journalctl -fu pve-auto-hook.service${CL}\n"

exit 0
