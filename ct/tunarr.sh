#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: chrisbenincasa
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tunarr.com/

APP="Tunarr"
var_tags="${var_tags:-iptv}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-5}"
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
  if [[ ! -d /opt/tunarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "tunarr" "chrisbenincasa/tunarr"; then
    msg_info "Stopping Service"
    systemctl stop tunarr
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    if [ -d "/usr/local/share/tunarr" ]; then
      tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" /usr/local/share/tunarr $STD
      msg_ok "Backup Created"
    else
      msg_error "Backup failed: /usr/local/share/tunarr does not exist"
    fi

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "tunarr" "chrisbenincasa/tunarr" "singlefile" "latest" "/opt/tunarr" "*linux-x64"

    msg_info "Starting Service"
    systemctl start tunarr
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi

  if check_for_gh_release "ersatztv-ffmpeg" "ErsatzTV/ErsatzTV-ffmpeg"; then
    msg_info "Stopping Service"
    systemctl stop tunarr
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ersatztv-ffmpeg" "ErsatzTV/ErsatzTV-ffmpeg" "prebuild" "latest" "/opt/ErsatzTV-ffmpeg" "*-linux64-gpl-7.1.tar.xz"

    msg_info "Set ErsatzTV-ffmpeg links"
    chmod +x /opt/ErsatzTV-ffmpeg/bin/*
    ln -sf /opt/ErsatzTV-ffmpeg/bin/ffmpeg /usr/local/bin/ffmpeg
    ln -sf /opt/ErsatzTV-ffmpeg/bin/ffplay /usr/local/bin/ffplay
    ln -sf /opt/ErsatzTV-ffmpeg/bin/ffprobe /usr/local/bin/ffprobe
    msg_ok "ffmpeg links set"

    msg_info "Starting Service"
    systemctl start tunarr
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
