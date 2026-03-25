#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://forgejo.org/

APP="Forgejo"
var_tags="${var_tags:-git}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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
  if [[ ! -d /opt/forgejo ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_codeberg_release "forgejo" "forgejo/forgejo"; then
    msg_info "Stopping Service"
    systemctl stop forgejo
    msg_ok "Stopped Service"

    fetch_and_deploy_codeberg_release "forgejo" "forgejo/forgejo" "singlefile" "latest" "/opt/forgejo" "forgejo-*-linux-amd64"
    ln -sf /opt/forgejo/forgejo /usr/local/bin/forgejo

    if grep -q "GITEA_WORK_DIR" /etc/systemd/system/forgejo.service; then
      msg_info "Updating Service File"
      sed -i "s/GITEA_WORK_DIR/FORGEJO_WORK_DIR/g" /etc/systemd/system/forgejo.service
      systemctl daemon-reload
      msg_ok "Updated Service File"
    fi

    msg_info "Starting Service"
    systemctl start forgejo
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at the latest version."
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
