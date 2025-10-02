#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wez/govee2mqtt

APP="Govee2MQTT"
var_tags="${var_tags:-iot;mqtt;bridge;smart-home}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-2}"
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
  if [[ ! -d /opt/govee2mqtt ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  
  msg_info "Stopping ${APP}"
  systemctl stop govee2mqtt
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP}"
  systemctl start docker
  ARCH=$(dpkg --print-architecture)
  case $ARCH in
    amd64) DOCKER_PLATFORM="linux/amd64" ;;
    arm64) DOCKER_PLATFORM="linux/arm64" ;;
    armhf) DOCKER_PLATFORM="linux/arm/v7" ;;
  esac
  
  TEMP_CONTAINER=$(docker create --platform=$DOCKER_PLATFORM ghcr.io/wez/govee2mqtt:latest)
  docker cp "$TEMP_CONTAINER:/app/govee" /opt/govee2mqtt/target/release/govee
  docker rm "$TEMP_CONTAINER"
  systemctl stop docker
  
  chmod +x /opt/govee2mqtt/target/release/govee
  chown govee2mqtt:govee2mqtt /opt/govee2mqtt/target/release/govee
  msg_ok "Updated ${APP}"

  msg_info "Starting ${APP}"
  systemctl start govee2mqtt
  msg_ok "Started ${APP}"
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"