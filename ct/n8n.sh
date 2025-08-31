#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://n8n.io/

APP="n8n"
var_tags="${var_tags:-automation}"
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
  if [[ ! -f /etc/systemd/system/n8n.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [ ! -f /opt/n8n.env ]; then
    sed -i 's|^Environment="N8N_SECURE_COOKIE=false"$|EnvironmentFile=/opt/n8n.env|' /etc/systemd/system/n8n.service
    HOST_IP=$(hostname -I | awk '{print $1}')
    mkdir -p /opt
    cat <<EOF >/opt/n8n.env
N8N_SECURE_COOKIE=false
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=$HOST_IP
EOF
  fi
  NODE_VERSION="22" setup_nodejs

  msg_info "Updating ${APP} LXC"
  $STD npm update -g n8n
  systemctl restart n8n
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5678${CL}"
