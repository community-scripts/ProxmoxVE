#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    __ __                     __   ________
   / //_/__  _________  ___  / /  / ____/ /__  ____ _____
  / ,< / _ \/ ___/ __ \/ _ \/ /  / /   / / _ \/ __ `/ __ \
 / /| /  __/ /  / / / /  __/ /  / /___/ /  __/ /_/ / / / /
/_/ |_\___/_/  /_/ /_/\___/_/   \____/_/\___/\__,_/_/ /_/

EOF
}

# Color variables
YW="\033[33m"
GN="\033[1;92m"
RD="\033[01;31m"
CL="\033[m"

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "kernel-clean" "pve"

# Detect current kernel
current_kernel=$(uname -r)
# Only list fully-installed (ii) versioned kernel packages; the pattern
# proxmox-kernel-X.Y.Z matches versioned kernels while excluding the
# two-segment meta-packages (proxmox-kernel-X.Y) and proxmox-kernel-helper.
available_kernels=$(dpkg --list |
  awk '/^ii/ {print $2}' |
  grep -E '^proxmox-kernel-[0-9]+\.[0-9]+\.[0-9]' |
  grep -v "$current_kernel" |
  sort -V)

header_info

if [ -z "$available_kernels" ]; then
  echo -e "${GN}No old kernels detected. Current kernel: ${current_kernel}${CL}"
  exit 0
fi

echo -e "${GN}Currently running kernel: ${current_kernel}${CL}"
echo -e "${YW}Available kernels for removal:${CL}"
echo "$available_kernels" | nl -w 2 -s '. '

echo -e "\n${YW}Select kernels to remove (e.g. 1,3 or 1-5 or 1-3,7):${CL}"
read -r selected

# Parse selection: supports single indices, ranges (e.g., 1-5), and combinations (e.g., 1,3-5,7)
selected_indices=()
IFS=',' read -r -a tokens <<<"$selected"
for token in "${tokens[@]}"; do
  if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    for ((i = BASH_REMATCH[1]; i <= BASH_REMATCH[2]; i++)); do
      selected_indices+=("$i")
    done
  else
    selected_indices+=("$token")
  fi
done

kernels_to_remove=()
for index in "${selected_indices[@]}"; do
  kernel=$(echo "$available_kernels" | sed -n "${index}p")
  if [ -n "$kernel" ]; then
    kernels_to_remove+=("$kernel")
  fi
done

if [ ${#kernels_to_remove[@]} -eq 0 ]; then
  echo -e "${RD}No valid selection made. Exiting.${CL}"
  exit 0
fi

# Confirm removal
echo -e "${YW}Kernels to be removed:${CL}"
printf "%s\n" "${kernels_to_remove[@]}"
read -rp "Proceed with removal? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
  echo -e "${RD}Aborted.${CL}"
  exit 0
fi

# Remove kernels
for kernel in "${kernels_to_remove[@]}"; do
  echo -e "${YW}Removing $kernel...${CL}"
  # Derive the major.minor meta-package name (e.g. proxmox-kernel-6.14)
  # from a versioned name like proxmox-kernel-6.14.11-9-pve-signed.
  minor_version=$(echo "$kernel" | sed -E 's/^proxmox-kernel-([0-9]+\.[0-9]+)\..*/\1/')
  meta="proxmox-kernel-${minor_version}"
  pkgs_to_remove=("$kernel")
  # Include the meta-package in the purge when it is installed and when
  # no other versioned kernel of the same minor version will remain
  # (the running kernel keeps it alive if it shares the same minor).
  if dpkg -l "$meta" 2>/dev/null | grep -q '^ii'; then
    remaining=$(dpkg --list |
      awk '/^ii/ {print $2}' |
      grep -E "^proxmox-kernel-${minor_version}\." |
      grep -v "^${kernel}$" |
      wc -l)
    if [ "$remaining" -eq 0 ]; then
      pkgs_to_remove+=("$meta")
    fi
  fi
  if apt-get purge -y "${pkgs_to_remove[@]}" >/dev/null 2>&1; then
    echo -e "${GN}Successfully removed: ${pkgs_to_remove[*]}${CL}"
  else
    echo -e "${RD}Failed to remove: ${pkgs_to_remove[*]}. Check dependencies.${CL}"
  fi
done

# Clean up and update GRUB
echo -e "${YW}Cleaning up...${CL}"
apt-get autoremove -y >/dev/null 2>&1 && update-grub >/dev/null 2>&1
echo -e "${GN}Cleanup and GRUB update complete.${CL}"
