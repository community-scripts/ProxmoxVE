#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.paperless-ngx.com/

# App Default Values
APP="Paperless-ngx"
var_tags="document;management"
var_cpu="2"
var_ram="2048"
var_disk="10"
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
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"