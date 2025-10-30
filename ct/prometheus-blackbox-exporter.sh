#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Marfnl
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/prometheus/blackbox_exporter

APP="Prometheus-Blackbox-Exporter"
var_tags="${var_tags:-monitoring;prometheus}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
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
  if [[ ! -d /opt/blackbox-exporter ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "blackbox-exporter" "prometheus/blackbox_exporter"; then
    msg_info "Stopping Service"
    systemctl stop blackbox-exporter
    msg_ok "Stopped Service"

    msg_info "Creating backup"
    mv /opt/blackbox-exporter/blackbox.yml /opt
    msg_ok "Backup created"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "blackbox-exporter" "prometheus/blackbox_exporter" "prebuild" "latest" "/opt/blackbox-exporter" "blackbox_exporter-*.linux-amd64.tar.gz"

    msg_info "Restoring backup"
    cp -r /opt/blackbox.yml /opt/blackbox-exporter
    rm -f /opt/blackbox.yml
    msg_ok "Backup restored"

    msg_info "Starting Service"
    systemctl start blackbox-exporter
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9115${CL}"
