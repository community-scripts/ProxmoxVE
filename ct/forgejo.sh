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
  msg_info "Stopping Service"
  systemctl stop forgejo
  msg_ok "Stopped Service"

  msg_info "Updating ${APP}"
  RELEASE=$(curl -fsSL https://codeberg.org/api/v1/repos/forgejo/forgejo/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+' | sed 's/^v//')
  curl -fsSL "https://codeberg.org/forgejo/forgejo/releases/download/v${RELEASE}/forgejo-${RELEASE}-linux-amd64" -o "forgejo-$RELEASE-linux-amd64"
  rm -rf /opt/forgejo/*
  cp -r forgejo-$RELEASE-linux-amd64 /opt/forgejo/forgejo-$RELEASE-linux-amd64
  chmod +x /opt/forgejo/forgejo-$RELEASE-linux-amd64
  ln -sf /opt/forgejo/forgejo-$RELEASE-linux-amd64 /usr/local/bin/forgejo
  msg_ok "Updated ${APP}"

  msg_info "Cleaning"
  rm -rf forgejo-$RELEASE-linux-amd64
  msg_ok "Cleaned"

  # Fix env var from older version of community script
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
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
