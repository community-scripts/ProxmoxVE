#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
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

# Detect current kernel
current_kernel=$(uname -r)
available_kernels=$(dpkg --list | grep 'kernel-.*-pve' | awk '{print $2}' | grep -v "$current_kernel" | sort -V)

header_info

if [ -z "$available_kernels" ]; then
  echo -e "${GN}No old kernels detected. Current kernel: ${current_kernel}${CL}"
  exit 0
fi

echo -e "${YW}Available kernels for removal:${CL}"
echo "$available_kernels" | nl -w 2 -s '. '

echo -e "\n${YW}Select kernels to remove (comma-separated, e.g., 1,2):${CL}"
read -r selected

# Parse selection
IFS=',' read -r -a selected_indices <<< "$selected"
kernels_to_remove=()

for index in "${selected_indices[@]}"; do
  kernel=$(echo "$available_kernels" | sed -n "${index}p")
  if [ -n "$kernel" ]; then
    kernels_to_remove+=("$kernel")
  fi
done

if [ ${#kernels_to_remove[@]} -eq 0 ]; then
  echo -e "${RD}No valid selection made. Exiting.${CL}"
  exit 1
fi

# Confirm removal
echo -e "${YW}Kernels to be removed:${CL}"
printf "%s\n" "${kernels_to_remove[@]}"
read -rp "Proceed with removal? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
  echo -e "${RD}Aborted.${CL}"
  exit 1
fi

# Remove kernels
for kernel in "${kernels_to_remove[@]}"; do
  echo -e "${YW}Removing $kernel...${CL}"
  if apt-get purge -y "$kernel" >/dev/null 2>&1; then
    echo -e "${GN}Successfully removed: $kernel${CL}"
  else
    echo -e "${RD}Failed to remove: $kernel. Check dependencies.${CL}"
  fi
done

# Clean up and update GRUB
echo -e "${YW}Cleaning up...${CL}"
apt-get autoremove -y >/dev/null 2>&1 && update-grub >/dev/null 2>&1
echo -e "${GN}Cleanup and GRUB update complete.${CL}"
