#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: stout01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/BerriAI/litellm

APP="LiteLLM"
var_tags="${var_tags:-ai;interface}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
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

  if [[ ! -f /etc/systemd/system/litellm.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping ${APP}"
  systemctl stop litellm
  msg_ok "Stopped ${APP}"

  VENV_PATH="/opt/litellm/.venv"
  PYTHON_VERSION="3.13" setup_uv

  msg_info "Updating $APP"
  $STD "$VENV_PATH/bin/python" -m pip install --upgrade litellm[proxy] prisma

  msg_info "Updating DB Schema"
  $STD uv --directory=/opt/litellm run litellm --config /opt/litellm/litellm.yaml --use_prisma_db_push --skip_server_startup
  msg_ok "DB Schema Updated"

  msg_info "Starting ${APP}"
  systemctl start litellm
  msg_ok "Started ${APP}"
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4000${CL}"
