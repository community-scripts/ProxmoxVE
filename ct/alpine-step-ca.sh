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

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
