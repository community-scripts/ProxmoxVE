#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ____                        __                                     
   / __ \____ _____  ___  _____/ /__  __________    ____  ____ __  __
  / /_/ / __ `/ __ \/ _ \/ ___/ / _ \/ ___/ ___/___/ __ \/ __ `/ |/_/
 / ____/ /_/ / /_/ /  __/ /  / /  __(__  |__  )___/ / / / /_/ />  <  
/_/    \__,_/ .___/\___/_/  /_/\___/____/____/   /_/ /_/\__, /_/|_|  
           /_/                                         /____/        
 
EOF
}
header_info
echo -e "Loading..."
APP="Paperless-ngx"
var_disk="10"
var_cpu="2"
var_ram="2048"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
  if [[ ! -d /opt/paperless ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/paperless-ngx/paperless-ngx/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')

  UPD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUPPORT" --radiolist --cancel-button Exit-Script "Spacebar = Select" 11 58 2 \
    "1" "Update Paperless-ngx to $RELEASE" ON \
    "2" "Paperless-ngx Credentials" OFF \
    3>&1 1>&2 2>&3)
  header_info
  check_container_storage
  check_container_resources
  if [ "$UPD" == "1" ]; then
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
	  if [[ "$(gs --version 2>/dev/null)" != "10.04.0" ]]; then
        msg_info "Updating Ghostscript (Patience)"
        cd /tmp
        wget -q https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10040/ghostscript-10.04.0.tar.gz
        tar -xzf ghostscript-10.04.0.tar.gz
        cd ghostscript-10.04.0
        ./configure &>/dev/null
        make &>/dev/null
        sudo make install &>/dev/null
        rm -rf /tmp/ghostscript*
        msg_ok "Ghostscript updated to 10.04.0"
      fi
      msg_info "Stopping all Paperless-ngx Services"
      systemctl stop paperless-consumer paperless-webserver paperless-scheduler paperless-task-queue.service
      msg_ok "Stopped all Paperless-ngx Services"

      msg_info "Updating to ${RELEASE}"
      cd ~
      wget -q https://github.com/paperless-ngx/paperless-ngx/releases/download/$RELEASE/paperless-ngx-$RELEASE.tar.xz
      tar -xf paperless-ngx-$RELEASE.tar.xz
      cp -r /opt/paperless/paperless.conf paperless-ngx/
      cp -r paperless-ngx/* /opt/paperless/
      cd /opt/paperless
      pip install -r requirements.txt &>/dev/null
      cd /opt/paperless/src
      /usr/bin/python3 manage.py migrate &>/dev/null
      echo "${RELEASE}" >/opt/${APP}_version.txt
      msg_ok "Updated to ${RELEASE}"

      msg_info "Cleaning up"
      cd ~
      rm paperless-ngx-$RELEASE.tar.xz
      rm -rf paperless-ngx
      msg_ok "Cleaned"

      msg_info "Starting all Paperless-ngx Services"
      systemctl start paperless-consumer paperless-webserver paperless-scheduler paperless-task-queue.service
      sleep 1
      msg_ok "Started all Paperless-ngx Services"
      msg_ok "Updated Successfully!\n"
    else
      msg_ok "No update required. ${APP} is already at ${RELEASE}"
    fi
    exit
  fi
  if [ "$UPD" == "2" ]; then
    cat paperless.creds
    exit
  fi
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:8000${CL} \n"
