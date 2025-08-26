#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

header_info() {
  clear
  cat <<"EOF"
    ____  ____ _____ __ __     __  __                           __   
   / __ \/ __ ) ___// // /    / / / /___  ____ __________ _____/ /__ 
  / /_/ / __  \__ \/ // /_   / / / / __ \/ __ `/ ___/ __ `/ __  / _ \
 / ____/ /_/ /__/ /__  __/  / /_/ / /_/ / /_/ / /  / /_/ / /_/ /  __/
/_/   /_____/____/  /_/     \____/ .___/\__, /_/   \__,_/\__,_/\___/ 
                                /_/    /____/                        
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

msg_info() { echo -ne " ${HOLD} ${YW}$1..."; }
msg_ok() { echo -e "${BFR} ${CM} ${GN}$1${CL}"; }
msg_error() { echo -e "${BFR} ${CROSS} ${RD}$1${CL}"; }

start_routines() {
  header_info
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS 3 BACKUP" --menu \
    "\nMake a backup of /etc/proxmox-backup to ensure recovery in worst case?" 14 58 2 \
    "yes" " " "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Backing up Proxmox Backup Server 3"
    tar czf "pbs3-etc-backup-$(date -I).tar.gz" -C "/etc" "proxmox-backup"
    msg_ok "Backed up Proxmox Backup Server 3"
    ;;
  no) msg_error "Selected no to Backup" ;;
  esac

  # --- Debian 13 Sources ---
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS 4 SOURCES" --menu \
    "Switch to Debian 13 (Trixie) sources for PBS 4?" 14 58 2 "yes" " " "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Switching to Debian 13 (Trixie) Sources"
    rm -f /etc/apt/sources.list.d/*.list
    sed -i '/proxmox/d;/bookworm/d' /etc/apt/sources.list || true
    cat >/etc/apt/sources.list.d/debian.sources <<EOF
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie-updates
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    msg_ok "Configured Debian 13 (Trixie) Sources"
    ;;
  no) msg_error "Selected no to Sources update" ;;
  esac

  # --- Enterprise Repo ---
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS4-ENTERPRISE" --menu \
    "Add 'pbs-enterprise' repository (for subscription users)?" 14 58 2 "yes" " " "no" " " \
    3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Adding 'pbs-enterprise' repository"
    cat >/etc/apt/sources.list.d/pbs-enterprise.sources <<EOF
Types: deb
URIs: https://enterprise.proxmox.com/debian/pbs
Suites: trixie
Components: pbs-enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
    msg_ok "Added 'pbs-enterprise' repository"
    ;;
  no) msg_error "Skipped enterprise repo" ;;
  esac

  # --- No-Subscription Repo ---
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS4-NO-SUBSCRIPTION" --menu \
    "Enable 'pbs-no-subscription' repository?" 14 58 2 "yes" " " "no" " " \
    3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Adding 'pbs-no-subscription' repository"
    cat >/etc/apt/sources.list.d/proxmox.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pbs
Suites: trixie
Components: pbs-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
    msg_ok "Added 'pbs-no-subscription' repository"
    ;;
  no) msg_error "Skipped no-subscription repo" ;;
  esac

  # --- Test Repo ---
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS4 TEST" --menu \
    "Add 'pbs-test' repository (disabled by default)?" 14 58 2 "yes" " " "no" " " \
    3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Adding 'pbs-test' repository (disabled)"
    cat >/etc/apt/sources.list.d/pbs-test.sources <<EOF
# Types: deb
# URIs: http://download.proxmox.com/debian/pbs
# Suites: trixie
# Components: pbs-test
# Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
    msg_ok "Added 'pbs-test' repository"
    ;;
  no) msg_error "Skipped test repo" ;;
  esac

  # --- Upgrade ---
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS 4 UPGRADE" --menu \
    "\nUpgrade to Proxmox Backup Server 4 now?" 11 58 2 "yes" " " "no" " " \
    3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Upgrading to Proxmox Backup Server 4 (Patience)"
    apt update
    DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confold" dist-upgrade -y
    msg_ok "System upgraded to PBS 4"
    ;;
  no) msg_error "Selected no to upgrade" ;;
  esac

  # --- Reboot ---
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "REBOOT" --menu \
    "\nReboot Proxmox Backup Server 4 now? (recommended)" 11 58 2 "yes" " " "no" " " \
    3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Rebooting PBS 4"
    sleep 2
    msg_ok "Upgrade Complete"
    reboot
    ;;
  no)
    msg_error "Selected no to Reboot (Reboot recommended)"
    msg_ok "Upgrade Complete"
    ;;
  esac
}

header_info
while true; do
  read -rp "Start the Upgrade to Proxmox Backup Server 4 Script (y/n)? " yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*)
    clear
    exit
    ;;
  *) echo "Please answer yes or no." ;;
  esac
done

start_routines
