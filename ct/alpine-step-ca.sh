#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/fwiegerinck/ProxmoxVE/refs/heads/step-ca/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: FWiegerinck
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/smallstep/certificates

# App Default Values
APP="Alpine-Step-CA"
var_tags="alpine;step-ca"
var_cpu="1"
var_ram="512"
var_disk="1024"
var_os="alpine"
var_version="3.20"
var_unprivileged="0"

# CA default values
DEFAULT_CA_NAME="HomeLab"


# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
   if ! apk -e info newt >/dev/null 2>&1; then
    apk add -q newt
  fi
  while true; do
    CHOICE=$(
      whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --menu "Select option" 11 58 1 \
        "1" "Check for Step CA Updates" 3>&2 2>&1 1>&3
    )
    exit_status=$?
    if [ $exit_status == 1 ]; then
      clear
      exit-script
    fi
    header_info
    case $CHOICE in
    1)
      apk update && apk upgrade
      exit
      ;;
    esac
  done
}

function caDetails() {
  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Configure Certificate Authority" "Now that we defined the container we need to configure the certificate authority." 8 58
  
  if CA_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Name of certificate authority" 8 58 "$DEFAULT_CA_NAME" --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
    if [ -z "$CA_NAME" ]; then
      CA_NAME="$DEFAULT_CA_NAME"
    fi
  else
    exit
  fi

  CA_DNS=()
  DEFAULT_CA_DNS_ENTRY="${HN}.local"
  if CA_DNS_ENTRY=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "DNS entry of Certificate Authority" 8 58 "$DEFAULT_CA_DNS_ENTRY" --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
    if [ -z "$CA_DNS_ENTRY" ]; then
      CA_DNS+=("$DEFAULT_CA_DNS_ENTRY")
    else
      CA_DNS+=("$CA_DNS_ENTRY")
    fi
  else
    exit
  fi

  while whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "Configure Certificate Authority" --yesno "Do you want to add another DNS entry?" 10 72  ; do

    if CA_DNS_ENTRY=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "DNS entry of Certificate Authority" 8 58 "" --title "Configure Certificate Authority" 3>&1 1>&2 2>&3); then
      if [ -n "$CA_DNS_ENTRY" ]; then
        CA_DNS+=("$CA_DNS_ENTRY")
      fi
    fi
  done

  echo -e "${CONTAINERID}${BOLD}${DGN}Name of CA: ${BGN}$CA_NAME${CL}"
  echo -e "CA DNS entries:"
  for DNS_ENTRY in ${CA_DNS[*]}; do
    echo -e "- $DNS_ENTRY"
  done

  export CA_NAME
  export CA_DNS
}

start
caDetails
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
