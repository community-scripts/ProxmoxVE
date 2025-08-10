#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
    clear
    cat <<"EOF"
    ____                                          ________                    ____             __                         __   __ _    ____  ___    
   / __ \_________  _  ______ ___  ____  _  __   / ____/ /__  ____ _____     / __ \_________  / /_  ____ _____  ___  ____/ /  / /| |  / /  |/  /____
  / /_/ / ___/ __ \| |/_/ __ `__ \/ __ \| |/_/  / /   / / _ \/ __ `/ __ \   / / / / ___/ __ \/ __ \/ __ `/ __ \/ _ \/ __  /  / / | | / / /|_/ / ___/
 / ____/ /  / /_/ />  </ / / / / / /_/ />  <   / /___/ /  __/ /_/ / / / /  / /_/ / /  / /_/ / / / / /_/ / / / /  __/ /_/ /  / /__| |/ / /  / (__  ) 
/_/   /_/   \____/_/|_/_/ /_/ /_/\____/_/|_|   \____/_/\___/\__,_/_/ /_/   \____/_/  / .___/_/ /_/\__,_/_/ /_/\___/\__,_/  /_____/___/_/  /_/____/  
                                                                                    /_/                                                             
EOF
}

# Function to check for orphaned LVM volumes
function find_orphaned_lvm {
    echo -e "\n🔍 Scanning for orphaned LVM volumes...\n"

    orphaned_volumes=()
    while read -r lv vg size seg_type; do
        # Exclude system-critical LVs and Ceph OSDs
        if [[ "$lv" == "data" || "$lv" == "root" || "$lv" == "swap" || "$lv" =~ ^osd-block- ]]; then
            continue
        fi

        # Exclude thin pools (any name)
        if [[ "$seg_type" == "thin-pool" ]]; then
            continue
        fi

        container_id=$(echo "$lv" | grep -oE "[0-9]+" | head -1)
        # Check if the ID exists as a VM or LXC container
        if [ -f "/etc/pve/lxc/${container_id}.conf" ] || [ -f "/etc/pve/qemu-server/${container_id}.conf" ]; then
            continue
        fi

        orphaned_volumes+=("$lv" "$vg" "$size")
    done < <(lvs --noheadings -o lv_name,vg_name,lv_size,seg_type --separator ' ' 2>/dev/null | awk '{print $1, $2, $3, $4}')

    # Display orphaned volumes
    echo -e "❗ The following orphaned LVM volumes were found:\n"
    printf "%-25s %-10s %-10s\n" "LV Name" "VG" "Size"
    printf "%-25s %-10s %-10s\n" "-------------------------" "----------" "----------"

    for ((i = 0; i < ${#orphaned_volumes[@]}; i += 3)); do
        printf "%-25s %-10s %-10s\n" "${orphaned_volumes[i]}" "${orphaned_volumes[i + 1]}" "${orphaned_volumes[i + 2]}"
    done
    echo ""
}

# Function to delete selected volumes
function delete_orphaned_lvm {
    for ((i = 0; i < ${#orphaned_volumes[@]}; i += 3)); do
        lv="${orphaned_volumes[i]}"
        vg="${orphaned_volumes[i + 1]}"
        size="${orphaned_volumes[i + 2]}"

        read -p "❓ Do you want to delete $lv (VG: $vg, Size: $size)? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "🗑️  Deleting $lv from $vg..."
            lvremove -f "$vg/$lv"
            if [ $? -eq 0 ]; then
                echo -e "✅ Successfully deleted $lv.\n"
            else
                echo -e "❌ Failed to delete $lv.\n"
            fi
        else
            echo -e "⚠️  Skipping $lv.\n"
        fi
    done
}

# Run script
header_info
find_orphaned_lvm
delete_orphaned_lvm

echo -e "✅ Cleanup process completed!\n"
