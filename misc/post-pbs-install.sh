#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

header_info() {
  clear
  cat <<"EOF"
    ____  ____ _____    ____             __     ____           __        ____
   / __ \/ __ ) ___/   / __ \____  _____/ /_   /  _/___  _____/ /_____ _/ / /
  / /_/ / __  \__ \   / /_/ / __ \/ ___/ __/   / // __ \/ ___/ __/ __ `/ / /
 / ____/ /_/ /__/ /  / ____/ /_/ (__  ) /_   _/ // / / (__  ) /_/ /_/ / / /
/_/   /_____/____/  /_/    \____/____/\__/  /___/_/ /_/____/\__/\__,_/_/_/

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
  VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS SOURCES" --menu "This will set the correct sources to update and install Proxmox Backup Server.\n \nChange to Proxmox Backup Server sources?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Changing to Proxmox Backup Server Sources"
    cat <<EOF >/etc/apt/sources.list
deb http://deb.debian.org/debian ${VERSION} main contrib
deb http://deb.debian.org/debian ${VERSION}-updates main contrib
deb http://security.debian.org/debian-security ${VERSION}-security main contrib
EOF
    msg_ok "Changed to Proxmox Backup Server Sources"
    ;;
  no)
    msg_error "Selected no to Correcting Proxmox Backup Server Sources"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS-ENTERPRISE" --menu "The 'pbs-enterprise' repository is only available to users who have purchased a Proxmox VE subscription.\n \nDisable 'pbs-enterprise' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Disabling 'pbs-enterprise' repository"
    cat <<EOF >/etc/apt/sources.list.d/pbs-enterprise.list
# deb https://enterprise.proxmox.com/debian/pbs ${VERSION} pbs-enterprise
EOF
    msg_ok "Disabled 'pbs-enterprise' repository"
    ;;
  no)
    msg_error "Selected no to Disabling 'pbs-enterprise' repository"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS-NO-SUBSCRIPTION" --menu "The 'pbs-no-subscription' repository provides access to all of the open-source components of Proxmox Backup Server.\n \nEnable 'pbs-no-subscription' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Enabling 'pbs-no-subscription' repository"
    cat <<EOF >/etc/apt/sources.list.d/pbs-install-repo.list
deb http://download.proxmox.com/debian/pbs ${VERSION} pbs-no-subscription
EOF
    msg_ok "Enabled 'pbs-no-subscription' repository"
    ;;
  no)
    msg_error "Selected no to Enabling 'pbs-no-subscription' repository"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS TEST" --menu "The 'pbstest' repository can give advanced users access to new features and updates before they are officially released.\n \nAdd (Disabled) 'pbstest' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Adding 'pbstest' repository and set disabled"
    cat <<EOF >/etc/apt/sources.list.d/pbstest-for-beta.list
# deb http://download.proxmox.com/debian/pbs ${VERSION} pbstest
EOF
    msg_ok "Added 'pbstest' repository"
    ;;
  no)
    msg_error "Selected no to Adding 'pbstest' repository"
    ;;
  esac

  if [[ ! -f /etc/apt/apt.conf.d/no-nag-script ]]; then
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUBSCRIPTION NAG" --menu "This will disable the nag message reminding you to purchase a subscription every time you log in to the web interface.\n \nDisable subscription nag?" 14 58 2 \
      "yes" " " \
      "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Support Subscriptions" "Supporting the software's development team is essential. Check their official website's Support Subscriptions for pricing. Without their dedicated work, we wouldn't have this exceptional software." 10 58
      msg_info "Disabling subscription nag"
      echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { echo 'Removing subscription nag from UI...'; sed -i '/data\.status.*{/{s/\!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" >/etc/apt/apt.conf.d/no-nag-script
      apt --reinstall install proxmox-widget-toolkit &>/dev/null
      msg_ok "Disabled subscription nag (Delete browser cache)"
      ;;
    no)
      whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Support Subscriptions" "Supporting the software's development team is essential. Check their official website's Support Subscriptions for pricing. Without their dedicated work, we wouldn't have this exceptional software." 10 58
      msg_error "Selected no to Disabling subscription nag"
      ;;
    esac
  fi

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "UPDATE" --menu "\nUpdate Proxmox Backup Server now?" 11 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Updating Proxmox Backup Server (Patience)"
    apt-get update &>/dev/null
    apt-get -y dist-upgrade &>/dev/null
    msg_ok "Updated Proxmox Backup Server"
    ;;
  no)
    msg_error "Selected no to Updating Proxmox Backup Server"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "REBOOT" --menu "\nReboot Proxmox Backup Server now? (recommended)" 11 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Rebooting Proxmox Backup Server"
    sleep 2
    msg_ok "Completed Post Install Routines"
    reboot
    ;;
  no)
    msg_error "Selected no to Rebooting Proxmox Backup Server (Reboot recommended)"
    msg_ok "Completed Post Install Routines"
    ;;
  esac
}

header_info
echo -e "\nThis script will Perform Post Install Routines.\n"
while true; do
  read -p "Start the Proxmox Backup Server Post Install Script (y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) clear; exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done

if command -v pveversion >/dev/null 2>&1; then
    echo -e "\n🛑  PVE Detected, Wrong Script!\n"
    exit 1
fi

start_routines
