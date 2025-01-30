#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

header_info() {
  clear
  cat <<"EOF"
    ____ _    ____________     __  ______  __________  ___    ____  ______
   / __ \ |  / / ____( __ )   / / / / __ \/ ____/ __ \/   |  / __ \/ ____/
  / /_/ / | / / __/ / __  |  / / / / /_/ / / __/ /_/ / /| | / / / / __/
 / ____/| |/ / /___/ /_/ /  / /_/ / ____/ /_/ / _, _/ ___ |/ /_/ / /___
/_/     |___/_____/\____/   \____/_/    \____/_/ |_/_/  |_/_____/_____/

EOF
}

RD=$(echo "\033[01;31m")
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

set -euo pipefail
shopt -s inherit_errexit nullglob

msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_error() {
  local msg="$1"
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}

start_routines() {
  header_info

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "PVE8 SOURCES" "This will set the correct sources to update and install Proxmox VE 8." 10 58
    msg_info "Changing to Proxmox VE 8 Sources"
    cat <<EOF >/etc/apt/sources.list
deb http://ftp.debian.org/debian bookworm main contrib
deb http://ftp.debian.org/debian bookworm-updates main contrib
deb http://security.debian.org/debian-security bookworm-security main contrib
EOF
    msg_ok "Changed to Proxmox VE 8 Sources"

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "PVE8-ENTERPRISE" "The 'pve-enterprise' repository is only available to users who have purchased a Proxmox VE subscription." 10 58
    msg_info "Disabling 'pve-enterprise' repository"
    cat <<EOF >/etc/apt/sources.list.d/pve-enterprise.list
# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise
EOF
    msg_ok "Disabled 'pve-enterprise' repository"

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "PVE8-NO-SUBSCRIPTION" "The 'pve-no-subscription' repository provides access to all of the open-source components of Proxmox VE." 10 58
    msg_info "Enabling 'pve-no-subscription' repository"
    cat <<EOF >/etc/apt/sources.list.d/pve-install-repo.list
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF
    msg_ok "Enabled 'pve-no-subscription' repository"

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "PVE8 CEPH PACKAGE REPOSITORIES" "The 'Ceph Package Repositories' provides access to both the 'no-subscription' and 'enterprise' repositories." 10 58
    msg_info "Enabling 'ceph package repositories'"
    cat <<EOF >/etc/apt/sources.list.d/ceph.list
# deb https://enterprise.proxmox.com/debian/ceph-quincy bookworm enterprise
deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription
EOF
    msg_ok "Enabled 'ceph package repositories'"

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "PVE8 TEST" "The 'pvetest' repository can give advanced users access to new features and updates before they are officially released (Disabled)." 10 58
    msg_info "Adding 'pvetest' repository and set disabled"
    cat <<EOF >/etc/apt/sources.list.d/pvetest-for-beta.list
# deb http://download.proxmox.com/debian/pve bookworm pvetest
EOF
    msg_ok "Added 'pvetest' repository"

  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "PVE8 UPDATE" "Updating to Proxmox VE 8" 10 58
    msg_info "Updating to Proxmox VE 8 (Patience)"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confold" dist-upgrade -y
    msg_ok "Updated to Proxmox VE 8"

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "REBOOT" --menu "\nReboot Proxmox VE 8 now? (recommended)" 11 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Rebooting Proxmox VE 8"
    sleep 2
    msg_ok "Completed Install Routines"
    reboot
    ;;
  no)
    msg_error "Selected no to Rebooting Proxmox VE 8 (Reboot recommended)"
    msg_ok "Completed Install Routines"
    ;;
  esac
}

header_info
while true; do
  read -p "Start the Update to Proxmox VE 8 Script (y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) clear; exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done

if ! command -v pveversion >/dev/null 2>&1; then
  header_info
  msg_error "\n No PVE Detected!\n"
  exit
fi

if ! pveversion | grep -Eq "pve-manager/(7\.4-(16|17|18|19))"; then
  header_info
  msg_error "This version of Proxmox Virtual Environment is not supported"
  echo -e "  PVE Version 7.4-16 or higher is required."
  echo -e "\nExiting..."
  sleep 3
  exit
fi

start_routines
