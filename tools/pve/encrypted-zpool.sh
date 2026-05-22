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

read -p "Enter the desired name for your new zpool: " POOL_NAME
read -p "Enter the absolute disk path (e.g., /dev/disk/by-id/nvme-...): " DISK

if [ -z "$POOL_NAME" ] || [ -z "$DISK" ]; then
    msg_error "Pool name and disk path cannot be empty."
    exit 1
fi

if [ ! -b "$DISK" ]; then
    msg_error "Disk $DISK not found or is not a block device."
    exit 1
fi

echo -e "\n${RD}WARNING: This will DESTROY all existing data on $DISK.${CL}"
read -p "Are you sure you want to continue? (y/N): " confirm
if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    msg_info "Aborted by user."
    exit 1
fi

echo -e "\n${YW}Enter encryption passphrase for '$POOL_NAME':${CL}"
read -s PASSPHRASE
echo -e "${YW}Confirm passphrase:${CL}"
read -s PASSPHRASE_CONFIRM
echo

if [ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]; then
    msg_error "Passphrases do not match. Aborting."
    exit 1
fi

msg_info "Creating encrypted zpool '$POOL_NAME' on $DISK..."

# Create the pool using best practices
echo "$PASSPHRASE" | zpool create \
    -O encryption=on \
    -O keyformat=passphrase \
    -O keylocation=prompt \
    -O compression=lz4 \
    -O atime=off \
    -O xattr=sa \
    "$POOL_NAME" "$DISK"

if [ $? -eq 0 ]; then
    msg_ok "Encrypted zpool '$POOL_NAME' has been created successfully."
else
    msg_error "Failed to create zpool."
    exit 1
fi
