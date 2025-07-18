#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ersatztv.org/

APP="ErsatzTV"
var_tags="${var_tags:-iptv}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-5}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors
function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/ErsatzTV ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/ErsatzTV/ErsatzTV/releases | grep -oP '"tag_name": "\Kv\K[^"]+' | head -n1)
  RELEASE_FFMPEG=$(curl -fsSL https://api.github.com/repos/ErsatzTV/ErsatzTV-ffmpeg/releases | grep -oP '"tag_name": "\K[^"]+' | head -n 1)

  if [[ "${RELEASE}" != "$(cat ~/.ersatztv 2>/dev/null)" ]] || [[ ! -f ~/.ersatztv ]]; then
    msg_info "Stopping ErsatzTV"
    systemctl stop ersatzTV
    msg_ok "Stopped ErsatzTV"

    fetch_and_deploy_gh_release "ersatztv" "ErsatzTV/ErsatzTV" "prebuild" "latest" "/opt/ErsatzTV" "*linux-x64.tar.gz"

    msg_info "Starting ErsatzTV"
    systemctl start ersatzTV
    msg_ok "Started ErsatzTV"

    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi

  if [[ "${RELEASE_FFMPEG}" != "$(cat ~/.ersatztv-ffmpeg 2>/dev/null)" ]] || [[ ! -f ~/.ersatztv-ffmpeg ]]; then
    msg_info "Stopping ErsatzTV"
    systemctl stop ersatzTV
    msg_ok "Stopped ErsatzTV"

    fetch_and_deploy_gh_release "ersatztv-ffmpeg" "ErsatzTV/ErsatzTV-ffmpeg" "prebuild" "latest" "/opt/ErsatzTV-ffmpeg" "*-linux64-gpl-7.1.tar.xz"

    msg_info "Set ErsatzTV-ffmpeg links"
    chmod +x /opt/ErsatzTV-ffmpeg/bin/*
    ln -sf /opt/ErsatzTV-ffmpeg/bin/ffmpeg /usr/local/bin/ffmpeg
    ln -sf /opt/ErsatzTV-ffmpeg/bin/ffplay /usr/local/bin/ffplay
    ln -sf /opt/ErsatzTV-ffmpeg/bin/ffprobe /usr/local/bin/ffprobe
    msg_ok "ffmpeg links set"

    msg_info "Starting ErsatzTV"
    systemctl start ersatzTV
    msg_ok "Started ErsatzTV"

    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ErsatzTV-ffmpeg is already at ${RELEASE_FFMPEG}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8409${CL}"
