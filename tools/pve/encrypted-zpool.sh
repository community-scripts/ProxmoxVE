#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: FullGreenGN
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

# --- Standard Community-Scripts Colors & Functions ---
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")

function msg_info() {
    echo -e "${BL}[Info]${CL} $1"
}
function msg_ok() {
    echo -e "${GN}[OK]${CL} $1"
}
function msg_error() {
    echo -e "${RD}[Error]${CL} $1"
}

# --- Script Logic ---
clear
cat << "EOF"
    ______                           __           __   ____                   __
   / ____/___  ____________  ______/ /____  ____/ /  /_  /  ____  ____  ____/ /
  / __/ / __ \/ ___/ ___/ / / / __  / _ \/ / __  /    / /  / __ \/ __ \/ __  /
 / /___/ / / / /__/ /  / /_/ / /_/ /  __/ / /_/ /    / /__/ /_/ / /_/ / /_/ /
/_____/_/ /_/\___/_/   \__, /\__,_/\___/  \__,_/    /____/ .___/\____/\__,_/
                      /____/                            /_/
EOF
echo -e "${YW}Automated Encrypted ZFS Pool Creation${CL}\n"

if [[ $EUID -ne 0 ]]; then
   msg_error "This script must be run as root."
   exit 1
fi

read -r -p "Enter the desired name for your new zpool: " POOL_NAME

if [ -z "$POOL_NAME" ]; then
    msg_error "Pool name cannot be empty."
    exit 1
fi

msg_info "Scanning for available disks..."
declare -a AVAILABLE_DISKS
declare -a DISK_LABELS

# Get all block devices of type disk, excluding loop, cdrom, and ram
mapfile -t DISKS < <(lsblk -d -n -e 1,7,11 -o NAME 2>/dev/null)

for disk in "${DISKS[@]}"; do
    is_os=0
    
    # 1. Check lsblk mountpoints (catches LVM root, ext4 root, swap, boot)
    mounts=$(lsblk -n -l -o MOUNTPOINT "/dev/$disk" 2>/dev/null)
    if echo "$mounts" | grep -q -E '^/$|^/boot|^\[SWAP\]'; then
        is_os=1
    fi

    # 2. Check pve Volume Group
    if command -v pvs >/dev/null 2>&1; then
        if pvs --noheadings -o vg_name "/dev/$disk"* 2>/dev/null | grep -q "pve"; then
            is_os=1
        fi
    fi

    # 3. Check rpool (ZFS)
    if command -v zpool >/dev/null 2>&1 && zpool status rpool >/dev/null 2>&1; then
        for part in $(lsblk -n -l -o KNAME "/dev/$disk" 2>/dev/null); do
            if zpool status rpool 2>/dev/null | grep -q -E "${part}$|${part}[[:space:]]"; then
                is_os=1
            fi
            if [ -d "/dev/disk/by-id" ]; then
                for link in /dev/disk/by-id/*; do
                    [ -e "$link" ] || continue
                    if [[ "$(readlink -f "$link")" == "/dev/$part" ]]; then
                        if zpool status rpool 2>/dev/null | grep -q -w "$(basename "$link")"; then
                            is_os=1
                        fi
                    fi
                done
            fi
        done
    fi

    if [[ $is_os -eq 0 ]]; then
        id_path=""
        if [ -d "/dev/disk/by-id" ]; then
            for f in /dev/disk/by-id/*; do
                [ -e "$f" ] || continue
                if [[ "$(readlink -f "$f")" == "/dev/$disk" ]]; then
                    if [[ "$f" == */nvme-* ]]; then id_path="$f"; break; fi
                    if [[ "$f" == */ata-* ]]; then id_path="$f"; continue; fi
                    [[ -z "$id_path" || "$id_path" == */wwn-* ]] && id_path="$f"
                fi
            done
        fi
        [[ -z "$id_path" ]] && id_path="/dev/$disk"
        
        size=$(lsblk -n -d -o SIZE "/dev/$disk" 2>/dev/null | tr -d ' ')
        model=$(lsblk -n -d -o MODEL "/dev/$disk" 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [[ -z "$model" ]] && model="Unknown Model"
        
        AVAILABLE_DISKS+=("$id_path")
        DISK_LABELS+=("$disk ($size) - $model [$id_path]")
    fi
done

if [[ ${#AVAILABLE_DISKS[@]} -eq 0 ]]; then
    msg_error "No available disks found (OS disks were filtered out)."
    exit 1
fi

echo -e "\n${YW}Available Disks:${CL}"
for i in "${!DISK_LABELS[@]}"; do
    echo -e "${GN}$((i+1))${CL}) ${DISK_LABELS[$i]}"
done
echo ""

while true; do
    read -r -p "Select a disk (1-${#AVAILABLE_DISKS[@]}): " selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#AVAILABLE_DISKS[@]}" ]; then
        DISK="${AVAILABLE_DISKS[$((selection-1))]}"
        break
    else
        echo -e "${RD}Invalid selection. Please try again.${CL}"
    fi
done

echo -e "\n${RD}WARNING: This will DESTROY all existing data on $DISK.${CL}"
read -r -p "Are you sure you want to continue? (y/N): " confirm
if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    msg_info "Aborted by user."
    exit 1
fi

echo -e "\n${YW}Enter encryption passphrase for '$POOL_NAME':${CL}"
read -r -s PASSPHRASE
echo
echo -e "${YW}Confirm passphrase:${CL}"
read -r -s PASSPHRASE_CONFIRM
echo

if [ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]; then
    msg_error "Passphrases do not match. Aborting."
    exit 1
fi

msg_info "Creating encrypted zpool '$POOL_NAME' on $DISK..."

# Create the pool using best practices (forced to wipe existing data and configured for Proxmox)
if printf '%s\n' "$PASSPHRASE" | zpool create -f \
    -o ashift=12 \
    -O encryption=on \
    -O keyformat=passphrase \
    -O keylocation=prompt \
    -O compression=lz4 \
    -O atime=off \
    -O xattr=sa \
    "$POOL_NAME" "$DISK"; then
    
    msg_ok "Encrypted zpool '$POOL_NAME' has been created successfully."
else
    msg_error "Failed to create zpool."
    exit 1
fi
