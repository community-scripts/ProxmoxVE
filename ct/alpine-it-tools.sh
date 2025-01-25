#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

# App Default Values
APP="Alpine-Docker"
var_tags="docker;alpine"
var_cpu="1"
var_ram="512"
var_disk="0.5"
var_os="alpine"
var_version="3.21"
var_unprivileged="1"

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
        "1" "Update IT-Tools" 3>&2 2>&1 1>&3
    )
    exit_status=$?
    if [ $exit_status == 1 ]; then
      clear
      exit-script
    fi
    header_info
    case $CHOICE in
    1)
      get_latest_release() {
          curl -s https://api.github.com/repos/CorentinTh/it-tools/releases/latest | grep '"tag_name":' | cut -d '"' -f4
      }
      LATEST_VERSION=$(get_latest_release)
      DOWNLOAD_URL="https://github.com/CorentinTh/it-tools/releases/download/$LATEST_VERSION/it-tools-${LATEST_VERSION#v}.zip"

      msg_info "Updating IT-Tools to version $LATEST_VERSION"
      curl -fsSL -o it-tools.zip "$DOWNLOAD_URL"
      mkdir -p /usr/share/nginx/html
      rm -rf /usr/share/nginx/html/*
      unzip -q it-tools.zip -d /tmp/it-tools
      cp -r /tmp/it-tools/dist/* /usr/share/nginx/html
      rm -rf /tmp/it-tools
      rm -f it-tools.zip
      msg_ok "IT-Tools updated to version $LATEST_VERSION"
      ;;
    esac
  done
}

start
build_container
description

msg_ok "Completed Successfully!\n"
