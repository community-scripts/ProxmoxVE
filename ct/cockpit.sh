#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck | Co-Author: havardthom
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://cockpit-project.org/

# App Default Values
APP="Cockpit"
var_tags="monitoring;network"
var_cpu="2"
var_ram="1024"
var_disk="4"
var_os="debian"
var_version="12"
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
  if [[ ! -d /etc/cockpit ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 4 \
    "1" "Update LXC" ON \
    "2" "Install cockpit-file-sharing" OFF \
    "3" "Install cockpit-identities" OFF \
    "4" "Install cockpit-navigator" OFF \
    3>&1 1>&2 2>&3)

  if [ "$UPD" == "1" ]; then
    msg_info "Updating ${APP} LXC"
    apt-get update &>/dev/null
    apt-get -y upgrade &>/dev/null
    msg_ok "Updated ${APP} LXC"
    exit
  fi
  if [ "$UPD" == "2" ]; then
    msg_info "Installing dependencies (patience)"
    apt-get install -y attr &>/dev/null
    apt-get install -y nfs-kernel-server &>/dev/null
    apt-get install -y samba &>/dev/null
    apt-get install -y samba-common-bin &>/dev/null
    apt-get install -y winbind &>/dev/null
    apt-get install -y gawk &>/dev/null
    msg_ok "Installed dependencies"
    msg_info "Installing Cockpit file sharing"
    wget -q $(curl -s https://api.github.com/repos/45Drives/cockpit-file-sharing/releases/latest | grep download | grep focal_all.deb | cut -d\" -f4)
    dpkg -i cockpit-file-sharing_*focal_all.deb &>/dev/null
    rm cockpit-file-sharing_*focal_all.deb
    msg_ok "Installed Cockpit file sharing"
    exit
  fi
  if [ "$UPD" == "3" ]; then
    msg_info "Installing dependencies (patience)"
    apt-get install -y psmisc &>/dev/null
    apt-get install -y samba &>/dev/null
    apt-get install -y samba-common-bin &>/dev/null
    msg_ok "Installed dependencies"
    msg_info "Installing Cockpit identities"
    wget -q $(curl -s https://api.github.com/repos/45Drives/cockpit-identities/releases/latest | grep download | grep focal_all.deb | cut -d\" -f4)
    dpkg -i cockpit-identities_*focal_all.deb &>/dev/null
    rm cockpit-identities_*focal_all.deb
    msg_ok "Installed Cockpit identities"
    exit
  fi
  if [ "$UPD" == "4" ]; then
    msg_info "Installing dependencies"
    apt-get install -y rsync &>/dev/null
    apt-get install -y zip &>/dev/null
    msg_ok "Installed dependencies"
    msg_info "Installing Cockpit navigator"
    wget -q $(curl -s https://api.github.com/repos/45Drives/cockpit-navigator/releases/latest | grep download | grep focal_all.deb | cut -d\" -f4)
    dpkg -i cockpit-navigator_*focal_all.deb &>/dev/null
    rm cockpit-navigator_*focal_all.deb
    msg_ok "Installed Cockpit navigator"
    exit
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9090${CL}"