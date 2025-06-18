#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CrazyWolf13/streamlink-webui

APP="streamlink-webui"
var_tags="${var_tags:-download,streaming}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/streamlink-webui ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/CrazyWolf13/streamlink-webui/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ "${RELEASE}" != "$(cat ~/.${APP} 2>/dev/null || cat /opt/${APP}_version.txt 2>/dev/null)" ]]; then
    msg_info "Starting Update"

    msg_info "Stopping $APP"
    systemctl stop ${APP}
    msg_ok "Stopped $APP"

    rm -rf /opt/${APP}
    NODE_VERSION="22"
    NODE_MODULE="npm,yarn"
    setup_nodejs
    setup_uv
    fetch_and_deploy_gh_release "streamlink-webui" "CrazyWolf13/streamlink-webui"

    msg_info "Updating $APP to v${RELEASE}"
    $STD uv venv /opt/"${APP}"/backend/src/.venv
    source /opt/"${APP}"/backend/src/.venv/bin/activate
    $STD uv pip install -r /opt/"${APP}"/backend/src/requirements.txt --python=/opt/"${APP}"/backend/src/.venv
    cd /opt/"${APP}"/frontend/src
    $STD yarn install
    $STD yarn build
    chmod +x /opt/"${APP}"/start.sh
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting $APP"
    systemctl start ${APP}
    msg_ok "Started $APP"

    msg_ok "Update Successful"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
