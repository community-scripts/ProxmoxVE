#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

header_info() {
  clear
  cat <<"EOF"
    ____  ____ __________    __  ______  __________  ___    ____  ______
   / __ \/ __ ) ___/__  /   / / / / __ \/ ____/ __ \/   |  / __ \/ ____/
  / /_/ / __  \__ \ /_ <   / / / / /_/ / / __/ /_/ / /| | / / / / __/
 / ____/ /_/ /__/ /__/ /  / /_/ / ____/ /_/ / _, _/ ___ |/ /_/ / /___
/_/   /_____/____/____/   \____/_/    \____/_/ |_/_/  |_/_____/_____/

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
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS 2 BACKUP" --menu "\nMake a backup of /etc/proxmox-backup to ensure that in the worst case, any relevant configuration can be recovered?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Backing up Proxmox Backup Server 2"
    tar czf "pbs2-etc-backup-$(date -I).tar.gz" -C "/etc" "proxmox-backup"
    msg_ok "Backed up Proxmox Backup Server 2"
    ;;
  no)
    msg_error "Selected no to Backing up Proxmox Backup Server 2"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS 3 SOURCES" --menu "This will set the correct sources to update and install Proxmox Backup Server 3.\n \nChange to Proxmox Backup Server 3 sources?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Changing to Proxmox Backup Server 3 Sources"
    cat <<EOF >/etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib
deb http://deb.debian.org/debian bookworm-updates main contrib
deb http://security.debian.org/debian-security bookworm-security main contrib
EOF
    msg_ok "Changed to Proxmox Backup Server 3 Sources"
    ;;
  no)
    msg_error "Selected no to Correcting Proxmox Backup Server 3 Sources"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS3-ENTERPRISE" --menu "The 'pbs-enterprise' repository is only available to users who have purchased a Proxmox VE subscription.\n \nDisable 'pbs-enterprise' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Disabling 'pbs-enterprise' repository"
    cat <<EOF >/etc/apt/sources.list.d/pbs-enterprise.list
# deb https://enterprise.proxmox.com/debian/pbs bookworm pbs-enterprise
EOF
    msg_ok "Disabled 'pbs-enterprise' repository"
    ;;
  no)
    msg_error "Selected no to Disabling 'pbs-enterprise' repository"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS3-NO-SUBSCRIPTION" --menu "The 'pbs-no-subscription' repository provides access to all of the open-source components of Proxmox Backup Server.\n \nEnable 'pbs-no-subscription' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Enabling 'pbs-no-subscription' repository"
    cat <<EOF >/etc/apt/sources.list.d/pbs-install-repo.list
deb http://download.proxmox.com/debian/pbs bookworm pbs-no-subscription
EOF
    msg_ok "Enabled 'pbs-no-subscription' repository"
    ;;
  no)
    msg_error "Selected no to Enabling 'pbs-no-subscription' repository"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS3 TEST" --menu "The 'pbstest' repository can give advanced users access to new features and updates before they are officially released.\n \nAdd (Disabled) 'pbstest' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Adding 'pbstest' repository and set disabled"
    cat <<EOF >/etc/apt/sources.list.d/pbstest-for-beta.list
# deb http://download.proxmox.com/debian/pbs bookworm pbstest
EOF
    msg_ok "Added 'pbstest' repository"
    ;;
  no)
    msg_error "Selected no to Adding 'pbstest' repository"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS 3 UPDATE" --menu "\nUpdate to Proxmox Backup Server 3 now?" 11 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Updating to Proxmox Backup Server 3 (Patience)"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confold" dist-upgrade -y
    msg_ok "Updated to Proxmox Backup Server 3"
    ;;
  no)
    msg_error "Selected no to Updating to Proxmox Backup Server 3"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "REBOOT" --menu "\nReboot Proxmox Backup Server 3 now? (recommended)" 11 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Rebooting Proxmox Backup Server 3"
    sleep 2
    msg_ok "Completed Install Routines"
    reboot
    ;;
  no)
    msg_error "Selected no to Rebooting Proxmox Backup Server 3 (Reboot recommended)"
    msg_ok "Completed Install Routines"
    ;;
  esac
}

header_info
while true; do
  read -p "Start the Update to Proxmox Backup Server 3 Script (y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) clear; exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done

start_routines
