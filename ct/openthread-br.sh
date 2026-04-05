#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openthread.io/guides/border-router

APP="OpenThread-BR"
var_tags="${var_tags:-thread;iot;border-router;matter}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-0}"
var_tun="${var_tun:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/ot-br-posix ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  cd /opt/ot-br-posix
  LOCAL_COMMIT=$(git rev-parse HEAD)
  $STD git fetch --depth 1 origin main
  REMOTE_COMMIT=$(git rev-parse origin/main)

  if [[ "${LOCAL_COMMIT}" == "${REMOTE_COMMIT}" ]]; then
    msg_ok "Already up to date (${LOCAL_COMMIT:0:7})"
    exit
  fi

  msg_info "Stopping Services"
  systemctl stop otbr-web
  systemctl stop otbr-agent
  msg_ok "Stopped Services"

  msg_info "Updating Source"
  $STD git reset --hard origin/main
  $STD git submodule update --depth 1 --init --recursive
  msg_ok "Updated Source"

  msg_info "Rebuilding OpenThread Border Router (Patience)"
  cd /opt/ot-br-posix/build
  $STD cmake -GNinja \
    -DBUILD_TESTING=OFF \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DOTBR_DBUS=ON \
    -DOTBR_MDNS=openthread \
    -DOTBR_REST=ON \
    -DOTBR_WEB=ON \
    -DOTBR_BORDER_ROUTING=ON \
    -DOTBR_BACKBONE_ROUTER=ON \
    -DOT_FIREWALL=ON \
    -DOT_POSIX_NAT64_CIDR="192.168.255.0/24" \
    ..
  $STD ninja
  $STD ninja install
  msg_ok "Rebuilt OpenThread Border Router"

  msg_info "Starting Services"
  systemctl start otbr-agent
  systemctl start otbr-web
  msg_ok "Started Services"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
