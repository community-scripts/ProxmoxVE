#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck | Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.rabbitmq.com/

APP="RabbitMQ"
var_tags="${var_tags:-mqtt}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /etc/rabbitmq ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if grep -q "dl.cloudsmith.io" /etc/apt/sources.list.d/rabbitmq.list; then
    rm -f /etc/apt/sources.list.d/rabbitmq.list
    setup_deb822_repo \
      "rabbitmq" \
      "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" \
      "https://deb1.rabbitmq.com/rabbitmq-server/debian/trixie" \
      "trixie"
  fi

  msg_info "Stopping Service"
  systemctl stop rabbitmq-server
  msg_ok "Stopped Service"

  msg_info "Updating..."
  $STD apt install --only-upgrade rabbitmq-server
  msg_ok "Updated successfully!"

  msg_info "Starting Service"
  systemctl start rabbitmq-server
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:15672${CL}"
