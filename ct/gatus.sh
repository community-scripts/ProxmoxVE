#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TwiN/gatus

APP="gatus"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -d /opt/gatus ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "gatus" "TwiN/gatus"; then
    msg_info "Stopping $APP"
    systemctl stop gatus
    msg_ok "Stopped $APP"

    mv /opt/gatus/config/config.yaml /opt
    rm -rf /opt/gatus
    fetch_and_deploy_gh_release "gatus" "TwiN/gatus"

    msg_info "Updating $APP"
    cd /opt/gatus
    $STD go mod tidy
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .
    setcap CAP_NET_RAW+ep gatus
    mv /opt/config.yaml config
    msg_ok "Updated $APP"

    msg_info "Starting $APP"
    systemctl start gatus
    msg_ok "Started $APP"
    msg_ok "Update Successful"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
