#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/marcopiovanello/yt-dlp-web-ui

APP="yt-dlp-webui"
var_tags="downloads;yt-dlp"
var_cpu="2"
var_ram="1024"
var_disk="4"
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
   if [[ ! -f /usr/local/bin/yt-dlp-webui ]]; then
      msg_error "No ${APP} Installation Found!"
      exit
   fi

   msg_info "Updating yt-dlp"
   $STD yt-dlp -U
   msg_ok "Updated yt-dlp"
   RELEASE=$(curl -fsSL https://api.github.com/repos/marcopiovanello/yt-dlp-web-ui/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
   if [[ "${RELEASE}" != "$(cat /opt/yt-dlp-webui_version.txt)" ]] || [[ ! -f /opt/yt-dlp-webui_version.txt ]]; then

      msg_info "Stopping $APP"
      systemctl stop yt-dlp-webui
      msg_ok "Stopped $APP"

      msg_info "Updating $APP to v${RELEASE}"
      rm -rf /usr/local/bin/yt-dlp-webui
      wget -q "https://github.com/marcopiovanello/yt-dlp-web-ui/releases/download/v${RELEASE}/yt-dlp-webui_linux-amd64" -O /usr/local/bin/yt-dlp-webui
      chmod +x /usr/local/bin/yt-dlp-webui
      msg_ok "Updated $APP LXC"

      msg_info "Starting $APP"
      systemctl start yt-dlp-webui
      msg_ok "Started $APP"
   else
      msg_ok "No update required. ${APP} is already at v${RELEASE}"
   fi
   exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3033${CL}"
