#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Execute within the Proxmox shell
# bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/hw-acceleration.sh)"

set -e
function header_info {
  clear
  cat <<"EOF"

   __ ___      __  ___              __             __  _
  / // / | /| / / / _ |___________ / /__ _______ _/ /_(_)__  ___
 / _  /| |/ |/ / / __ / __/ __/ -_) / -_) __/ _ `/ __/ / _ \/ _ \
/_//_/ |__/|__/ /_/ |_\__/\__/\__/_/\__/_/  \_,_/\__/_/\___/_//_/

EOF
}

YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
set -e
header_info
echo "Loading..."
function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

if ! pveversion | grep -Eq "pve-manager/(8\.[1-3])"; then
  msg_error "This version of Proxmox Virtual Environment is not supported"
  echo -e "Requires PVE Version 8.1 or higher"
  echo -e "Exiting..."
  sleep 2
  exit
fi

whiptail --backtitle "Proxmox VE Helper Scripts" --title "Add Intel HW Acceleration" --yesno "This Will Add Intel HW Acceleration to an existing LXC Container. Proceed?" 8 72 || exit
NODE=$(hostname)
PREV_MENU=()
MSG_MAX_LENGTH=0
privileged_containers=$(pct list | awk 'NR>1 && system("grep -q \047unprivileged: 1\047 /etc/pve/lxc/" $1 ".conf")')

if [ -z "$privileged_containers" ]; then
    whiptail --msgbox "No Privileged Containers Found." 10 58
    exit
fi

while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  PREV_MENU+=("$TAG" "$ITEM " "OFF")
done < <(echo "$privileged_containers")

privileged_container=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Privileged Containers on $NODE" --checklist "\nSelect a Container To Add Intel HW Acceleration:\n" 16 $((MSG_MAX_LENGTH + 23)) 6 "${PREV_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit
header_info
read -r -p "Verbose mode? <y/N> " prompt
  if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  STD=""
  else
  STD="silent"
  fi
header_info

cat <<EOF >>/etc/pve/lxc/${privileged_container}.conf
lxc.cgroup2.devices.allow: c 226:0 rwm
lxc.cgroup2.devices.allow: c 226:128 rwm
lxc.cgroup2.devices.allow: c 29:0 rwm
lxc.mount.entry: /dev/fb0 dev/fb0 none bind,optional,create=file
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file
EOF

read -r -p "Do you need the intel-media-va-driver-non-free driver (Debian 12 only)? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  header_info
  msg_info "Installing Hardware Acceleration (non-free)"
  pct exec ${privileged_container} -- bash -c "cat <<EOF >/etc/apt/sources.list.d/non-free.list

deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware

deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
EOF"

  pct exec ${privileged_container} -- bash -c "silent() { \"\$@\" >/dev/null 2>&1; } && $STD apt-get update && $STD apt-get install -y intel-media-va-driver-non-free ocl-icd-libopencl1 intel-opencl-icd vainfo intel-gpu-tools && $STD adduser \$(id -u -n) video && $STD adduser \$(id -u -n) render"
  msg_ok "Installed Hardware Acceleration (non-free)"
else
  header_info
  msg_info "Installing Hardware Acceleration"
  pct exec ${privileged_container} -- bash -c "silent() { \"\$@\" >/dev/null 2>&1; } && $STD apt-get install -y va-driver-all ocl-icd-libopencl1 intel-opencl-icd vainfo intel-gpu-tools && chgrp video /dev/dri && chmod 755 /dev/dri && $STD adduser \$(id -u -n) video && $STD adduser \$(id -u -n) render"
  msg_ok "Installed Hardware Acceleration"
fi
sleep 1
whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Added tools" "vainfo, execute command 'vainfo'\nintel-gpu-tools, execute command 'intel_gpu_top'" 8 58

msg_ok "Completed Successfully!\n"
echo -e "Reboot container ${BL}$privileged_container${CL} to apply the new settings\n"
