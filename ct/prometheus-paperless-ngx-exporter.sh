#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Andy Grunwald (andygrunwald)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hansmi/prometheus-paperless-exporter

APP="Prometheus-Paperless-NGX-Exporter"
var_tags="${var_tags:-monitoring;alerting}"
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
  if [[ ! -f /etc/systemd/system/prometheus-paperless-ngx-exporter.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "prom-paperless-exp" "hansmi/prometheus-paperless-exporter"; then
    msg_info "Stopping Service"
    systemctl stop prometheus-paperless-ngx-exporter
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "prom-paperless-exp" "hansmi/prometheus-paperless-exporter" "binary"

    msg_info "Starting Service"
    systemctl start prometheus-paperless-ngx-exporter
    msg_ok "Started Service"
    msg_ok "Updated Successfully"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8081/metrics${CL}"
