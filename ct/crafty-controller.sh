#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitlab.com/crafty-controller/crafty-4

APP="Crafty-Controller"
var_tags="gaming"
var_cpu="2"
var_ram="4096"
var_disk="16"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/crafty-controller ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
   
    RELEASE=$(curl -s "https://gitlab.com/api/v4/projects/20430749/releases" | grep -o '"tag_name":"v[^"]*"' | head -n 1 | sed 's/"tag_name":"v//;s/"//')
    if [[ ! -f /opt/crafty-controller_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/crafty-controller_version.txt)" ]]; then
      
      msg_info "Stopping Crafty-Controller"
      systemctl stop crafty-controller
      msg_ok "Stopped Crafty-Controller"

      msg_info "Creating Backup of config"
      cp -a /opt/crafty-controller/crafty/crafty-4/app/config/. /opt/crafty-controller/backup
      rm /opt/crafty-controller/backup/version.json
      rm /opt/crafty-controller/backup/credits.json
      rm /opt/crafty-controller/backup/logging.json
      rm /opt/crafty-controller/backup/default.json.example
      rm /opt/crafty-controller/backup/motd_format.json
      msg_ok "Backup Created"
      
      msg_info "Updating Crafty-Controller to v${RELEASE}"
      wget -q "https://gitlab.com/crafty-controller/crafty-4/-/archive/v${RELEASE}/crafty-4-v${RELEASE}.zip"
      unzip -q crafty-4-v${RELEASE}.zip
      cp -a crafty-4-v${RELEASE}/. /opt/crafty-controller/crafty/crafty-4/
      rm -rf crafty-4-v${RELEASE}
      cd /opt/crafty-controller/crafty/crafty-4
      sudo -u crafty bash -c '
        source /opt/crafty-controller/crafty/.venv/bin/activate
        pip3 install --no-cache-dir -r requirements.txt
      ' &>/dev/null
      echo "${RELEASE}" >"/opt/crafty-controller_version.txt"
      msg_ok "Updated Crafty-Controller to v${RELEASE}"

      msg_info "Restoring Backup of config"
      cp -a /opt/crafty-controller/backup/. /opt/crafty-controller/crafty/crafty-4/app/config
      rm -rf /opt/crafty-controller/backup
      chown -R crafty:crafty /opt/crafty-controller/
      msg_ok "Backup Restored"

      msg_info "Starting Crafty-Controller"
      systemctl start crafty-controller
      msg_ok "Started Crafty-Controller"

      msg_ok "Updated Successfully"
      exit
  else
    msg_ok "No update required. Crafty-Controller is already at v${RELEASE}."
  fi
}


start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8443${CL}"
