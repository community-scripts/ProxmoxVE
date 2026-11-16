#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/unslothai/unsloth

APP="Unsloth"
var_tags="${var_tags:-ai;llm}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-40}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_gpu="${var_gpu:-yes}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/unsloth ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping Service"
  systemctl stop unsloth
  msg_ok "Stopped Service"

  if [[ -d /dev/dri || -e /dev/nvidia0 || -e /dev/kfd ]]; then
    ENABLE_GPU="yes" setup_hwaccel
  fi

  msg_info "Updating ${APP} (Patience)"
  curl -fsSL https://unsloth.ai/install.sh -o /tmp/unsloth-install.sh
  export UNSLOTH_STUDIO_HOME=/opt/unsloth
  export UNSLOTH_SKIP_AUTOSTART=1
  export UNSLOTH_PYTHON=3.12
  $STD sh /tmp/unsloth-install.sh
  unset UNSLOTH_SKIP_AUTOSTART UNSLOTH_PYTHON
  rm -f /tmp/unsloth-install.sh
  msg_ok "Updated ${APP}"

  msg_info "Starting Service"
  systemctl start unsloth
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8888${CL}"
echo -e "${INFO}${YW}Login credentials: ~/unsloth.creds (inside the container)${CL}"
