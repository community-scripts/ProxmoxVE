#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/chverma/ProxmoxVE/feature/add-whisper-lxc-script/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: chverma
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rhasspy/wyoming-faster-whisper

APP="Wyoming Faster Whisper"
var_tags="${var_tags:-ai;speech-to-text}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-15}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/wyoming-faster-whisper ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating base system"
  $STD apt update
  $STD apt upgrade -y
  msg_ok "Base system updated"

  msg_info "Stopping Wyoming Whisper Service"
  systemctl stop wyoming-whisper
  msg_ok "Stopped Service"

  msg_info "Updating Wyoming Faster Whisper"
  cd /opt/wyoming-faster-whisper
  $STD git pull
  $STD /opt/wyoming-faster-whisper/script/setup
  msg_ok "Updated Wyoming Faster Whisper"

  msg_info "Updating FFmpeg"
  $STD apt install --only-upgrade -y ffmpeg
  msg_ok "Updated FFmpeg"

  msg_info "Starting Wyoming Whisper Service"
  systemctl start wyoming-whisper
  msg_ok "Started Service"

  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Wyoming Whisper is running at:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}tcp://${IP}:10300${CL}"
echo -e "${INFO}${YW} Add to Home Assistant configuration.yaml:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}wyoming:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}  - uri: tcp://${IP}:10300${CL}"
echo -e ""
echo -e "${INFO}${YW} SSH Access:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}ssh root@${IP}${CL}"
echo -e "${INFO}${YW} Verify service status:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}systemctl status wyoming-whisper${CL}"
echo -e "${INFO}${YW} View logs:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}journalctl -u wyoming-whisper -f${CL}"
