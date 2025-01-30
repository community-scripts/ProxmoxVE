#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    __ __                     __   ____  _
   / //_/__  _________  ___  / /  / __ \(_)___
  / ,< / _ \/ ___/ __ \/ _ \/ /  / /_/ / / __ \
 / /| /  __/ /  / / / /  __/ /  / ____/ / / / /
/_/ |_\___/_/  /_/ /_/\___/_/  /_/   /_/_/ /_/

EOF
}
YW=$(echo "\033[33m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
current_kernel=$(uname -r)
available_kernels=$(dpkg --list | grep 'kernel-.*-pve' | awk '{print substr($2, 16, length($2)-22)}')
header_info

function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE Kernel Pin" --yesno "This will Pin/Unpin Kernel Images, Proceed?" 10 68 || exit

  KERNEL_MENU=()
  MSG_MAX_LENGTH=0
while read -r TAG ITEM; do
  OFFSET=2
  ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
  KERNEL_MENU+=("$TAG" "$ITEM " "OFF")
done < <(echo "$available_kernels")

pin_kernel=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Current Kernel $current_kernel" --radiolist "\nSelect Kernel to pin:\nCancel to Unpin any Kernel" 16 $((MSG_MAX_LENGTH + 58)) 6 "${KERNEL_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"') || exit
[ -z "$pin_kernel" ] && {
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "No Kernel Selected" --msgbox "It appears that no Kernel was selected\nUnpinning any pinned Kernel" 10 68
  msg_info "Unpinning any Kernel"
  proxmox-boot-tool kernel unpin &>/dev/null
  msg_ok "Unpinned any Kernel\n"
  proxmox-boot-tool kernel list
  echo ""
  msg_ok "Finished\n"
  echo -e "${RD} REBOOT${CL}"
  exit
}
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE Kernel Pin" --yesno "Would you like to pin the $pin_kernel Kernel?" 10 68 || exit

msg_info "Pinning $pin_kernel"
proxmox-boot-tool kernel pin $pin_kernel &>/dev/null
msg_ok "Successfully Pinned $pin_kernel\n"
proxmox-boot-tool kernel list
echo ""
msg_ok "Finished\n"
echo -e "${RD} REBOOT${CL}"
