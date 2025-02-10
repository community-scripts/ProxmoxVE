#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: thost96 (thost96)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

header_info() {
  clear
  cat <<"EOF"
    ____  __  _________   ____             __     ____           __        ____
   / __ \/  |/  / ____/  / __ \____  _____/ /_   /  _/___  _____/ /_____ _/ / /
  / /_/ / /|_/ / / __   / /_/ / __ \/ ___/ __/   / // __ \/ ___/ __/ __ `/ / / 
 / ____/ /  / / /_/ /  / ____/ /_/ (__  ) /_   _/ // / / (__  ) /_/ /_/ / / /  
/_/   /_/  /_/\____/  /_/    \____/____/\__/  /___/_/ /_/____/\__/\__,_/_/_/   
                                                                               
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
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PMG SOURCES" --menu "This will set the correct sources to update and install Proxmox Mail Gateway.\n \nChange to Proxmox Mail Gateway sources?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Changing to Proxmox Mail Gateway Sources"
    cat <<EOF >/etc/apt/sources.list
deb http://deb.debian.org/debian ${VERSION} main contrib
deb http://deb.debian.org/debian ${VERSION}-updates main contrib
deb http://security.debian.org/debian-security ${VERSION}-security main contrib
EOF
    msg_ok "Changed to Proxmox Mail Gateway Sources"
    ;;
  no)
    msg_error "Selected no to Correcting Proxmox Mail Gateway Sources"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PMG-ENTERPRISE" --menu "The 'pmg-enterprise' repository is only available to users who have purchased a Proxmox Mail Gateway subscription.\n \nDisable 'pmg-enterprise' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Disabling 'pmg-enterprise' repository"
    cat <<EOF >/etc/apt/sources.list.d/pmg-enterprise.list
# deb https://enterprise.proxmox.com/debian/pmg ${VERSION} pmg-enterprise
EOF
    msg_ok "Disabled 'pmg-enterprise' repository"
    ;;
  no)
    msg_error "Selected no to disabling 'pmg-enterprise' repository"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PMG-NO-SUBSCRIPTION" --menu "The 'pmg-no-subscription' repository provides access to all of the open-source components of Proxmox Mail Gateway.\n \nEnable 'pmg-no-subscription' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Enabling 'pmg-no-subscription' repository"
    cat <<EOF >/etc/apt/sources.list.d/pmg-install-repo.list
deb http://download.proxmox.com/debian/pmg ${VERSION} pmg-no-subscription
EOF
    msg_ok "Enabled 'pmg-no-subscription' repository"
    ;;
  no)
    msg_error "Selected no to enabling 'pmg-no-subscription' repository"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PMG TEST" --menu "The 'pmgtest' repository can give advanced users access to new features and updates before they are officially released.\n \nAdd (Disabled) 'pmgtest' repository?" 14 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Adding 'pmgtest' repository and set disabled"
    cat <<EOF >/etc/apt/sources.list.d/pmgtest-for-beta.list
# deb http://download.proxmox.com/debian/pmg ${VERSION} pmgtest
EOF
    msg_ok "Added 'pmgtest' repository"
    ;;
  no)
    msg_error "Selected no to adding 'pmgtest' repository"
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
      # Normal GUI:
      echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { echo 'Removing subscription nag from UI...'; sed -i '/.*data\.status.*{/{s/\!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" >/etc/apt/apt.conf.d/no-nag-script
      # JS-Library used when accessing via mobile device browser
      echo "DPkg::Post-Invoke { \"dpkg -V pmg-gui | grep -q '/pmgmanagerlib-mobile\.js$'; if [ \$? -eq 1 ]; then { echo 'Removing subscription nag from Mobile UI...'; sed -i '/data\.status.*{/{s/\!//;s/active/NoMoreNagging/}' /usr/share/javascript/pmg-gui/js/pmgmanagerlib-mobile.js; }; fi\"; };" >>/etc/apt/apt.conf.d/no-nag-script
      apt --reinstall install proxmox-widget-toolkit pmg-gui &>/dev/null
      msg_ok "Disabled subscription nag (Delete browser cache)"
      ;;
    no)
      whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Support Subscriptions" "Supporting the software's development team is essential. Check their official website's Support Subscriptions for pricing. Without their dedicated work, we wouldn't have this exceptional software." 10 58
      msg_error "Selected no to disabling subscription nag"
      ;;
    esac
  fi

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "UPDATE" --menu "\nUpdate Proxmox Mail Gateway now?" 11 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Updating Proxmox Mail Gateway (Patience)"
    apt-get update &>/dev/null
    apt-get -y dist-upgrade &>/dev/null
    msg_ok "Updated Proxmox Mail Gateway"
    ;;
  no)
    msg_error "Selected no to updating Proxmox Mail Gateway"
    ;;
  esac

  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "REBOOT" --menu "\nReboot Proxmox Mail Gateway now? (recommended)" 11 58 2 \
    "yes" " " \
    "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Rebooting Proxmox Mail Gateway"
    sleep 2
    msg_ok "Completed Post Install Routines"
    reboot
    ;;
  no)
    msg_error "Selected no to reboot Proxmox Mail Gateway (Reboot recommended)"
    msg_ok "Completed Post Install Routines"
    ;;
  esac
}

header_info
echo -e "\nThis script will Perform Post Install Routines.\n"
while true; do
  read -p "Start the Proxmox Mail Gateway Post Install Script (y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) clear; exit ;;
  *) echo "Please answer yes or no." ;;
  esac
done

start_routines
