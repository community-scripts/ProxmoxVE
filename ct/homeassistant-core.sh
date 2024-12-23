#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.home-assistant.io/

# App Default Values
APP="Home Assistant-Core"
var_tags="automation;smarthome"
var_cpu="2"
var_ram="1024"
var_disk="8"
var_os="ubuntu"
var_version="24.04"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /srv/homeassistant ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  PY=$(ls /srv/homeassistant/lib/)
  IP=$(hostname -I | awk '{print $1}')
  UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "UPDATE" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 4 \
    "1" "Update Core" ON \
    "2" "Install HACS" OFF \
    "3" "Install FileBrowser" OFF \
    3>&1 1>&2 2>&3)
  if [ "$UPD" == "1" ]; then
    if (whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "SELECT BRANCH" --yesno "Use Beta Branch?" 10 58); then
      clear
      header_info
      echo -e "${GN}Updating to Beta Version${CL}"
      BR="--pre "
    else
      clear
      header_info
      echo -e "${GN}Updating to Stable Version${CL}"
      BR=""
    fi
    if [[ "$PY" == "python3.11" ]]; then echo -e "⚠️  Home Assistant will soon require Python 3.12."; fi

    msg_info "Stopping Home Assistant"
    systemctl stop homeassistant
    msg_ok "Stopped Home Assistant"

    msg_info "Updating Home Assistant"
    source /srv/homeassistant/bin/activate
    uv pip install ${BR}--upgrade homeassistant &>/dev/null
    msg_ok "Updated Home Assistant"

    msg_info "Starting Home Assistant"
    systemctl start homeassistant
    sleep 2
    msg_ok "Started Home Assistant"
    msg_ok "Update Successful"
    echo -e "\n  Go to http://${IP}:8123 \n"
    exit
  fi
  if [ "$UPD" == "2" ]; then
    msg_info "Installing Home Assistant Community Store (HACS)"
    apt update &>/dev/null
    apt install unzip &>/dev/null
    cd .homeassistant
    bash <(curl -fsSL https://get.hacs.xyz) &>/dev/null
    msg_ok "Installed Home Assistant Community Store (HACS)"
    echo -e "\n Reboot Home Assistant and clear browser cache then Add HACS integration.\n"
    exit
  fi
  if [ "$UPD" == "3" ]; then
    set +Eeuo pipefail
    read -r -p "Would you like to use No Authentication? <y/N> " prompt
    msg_info "Installing FileBrowser"
    RELEASE=$(curl -fsSL https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep -o '"tag_name": ".*"' | sed 's/"//g' | sed 's/tag_name: //g')
    curl -fsSL https://github.com/filebrowser/filebrowser/releases/download/$RELEASE/linux-amd64-filebrowser.tar.gz | tar -xzv -C /usr/local/bin &>/dev/null

    if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
      filebrowser config init -a '0.0.0.0' &>/dev/null
      filebrowser config set -a '0.0.0.0' &>/dev/null
      filebrowser config set --auth.method=noauth &>/dev/null
      filebrowser users add ID 1 --perm.admin &>/dev/null
    else
      filebrowser config init -a '0.0.0.0' &>/dev/null
      filebrowser config set -a '0.0.0.0' &>/dev/null
      filebrowser users add admin helper-scripts.com --perm.admin &>/dev/null
    fi
    msg_ok "Installed FileBrowser"

    msg_info "Creating Service"
    service_path="/etc/systemd/system/filebrowser.service"
    echo "[Unit]
Description=Filebrowser
After=network-online.target
[Service]
User=root
WorkingDirectory=/root/
ExecStart=/usr/local/bin/filebrowser -r /root/.homeassistant
[Install]
WantedBy=default.target" >$service_path

    systemctl enable --now -q filebrowser.service
    msg_ok "Created Service"

    msg_ok "Completed Successfully!\n"
    echo -e "FileBrowser should be reachable by going to the following URL.
         ${BL}http://$IP:8080${CL}   admin|helper-scripts.com\n"
    exit
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8123${CL}"
