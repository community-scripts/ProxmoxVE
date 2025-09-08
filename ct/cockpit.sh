#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck | Co-Author: havardthom
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://cockpit-project.org/

APP="Cockpit"
var_tags="${var_tags:-monitoring;network}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
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
    $STD apt-get update
    $STD apt-get -y upgrade
    msg_ok "Updated ${APP} LXC"
    exit
  fi

  if [ "$UPD" == "2" ]; then
    msg_info "Installing dependencies (patience)"
    $STD apt-get install -y \
      attr \
      nfs-kernel-server \
      samba \
      samba-common-bin \
      winbind \
      gawk
    msg_ok "Installed dependencies"
    msg_info "Installing Cockpit file sharing"
    URL=$(curl -fsSL https://api.github.com/repos/45Drives/cockpit-file-sharing/releases/latest | grep download | grep focal_all.deb | cut -d\" -f4)
    FILE=$(basename "$URL")
    curl -fsSL "$URL" -o "$FILE"
    $STD dpkg -i "$FILE" || $STD apt-get install -f -y
    rm -f "$FILE"
    msg_ok "Installed Cockpit file sharing"
    exit
  fi

  if [ "$UPD" == "3" ]; then
    msg_info "Installing dependencies (patience)"
    $STD apt-get install -y \
      psmisc \
      samba \
      samba-common-bin
    msg_ok "Installed dependencies"
    msg_info "Installing Cockpit identities"
    URL=$(curl -fsSL https://api.github.com/repos/45Drives/cockpit-identities/releases/latest | grep download | grep focal_all.deb | cut -d\" -f4)
    FILE=$(basename "$URL")
    curl -fsSL "$URL" -o "$FILE"
    $STD dpkg -i "$FILE" || $STD apt-get install -f -y
    rm -f "$FILE"
    msg_ok "Installed Cockpit identities"
    exit
  fi

  if [ "$UPD" == "4" ]; then
    msg_info "Installing dependencies"
    $STD apt-get install -y \
      rsync \
      zip
    msg_ok "Installed dependencies"
    msg_info "Installing Cockpit navigator"
    URL=$(curl -fsSL https://api.github.com/repos/45Drives/cockpit-navigator/releases/latest | grep download | grep focal_all.deb | cut -d\" -f4)
    FILE=$(basename "$URL")
    curl -fsSL "$URL" -o "$FILE"
    $STD dpkg -i "$FILE" || $STD apt-get install -f -y
    rm -f "$FILE"
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
