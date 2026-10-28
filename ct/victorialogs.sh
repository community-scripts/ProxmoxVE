#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Nicolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://victoriametrics.com/products/victorialogs/

APP="VictoriaLogs"
var_tags="${var_tags:-logging;monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_arm64="${var_arm64:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/victorialogs ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if ! grep -q -- '-syslog.listenAddr' /etc/systemd/system/victorialogs.service; then
    msg_info "Enabling Syslog Ingestion"
    sed -i '/^ExecStart=/ s|$| -syslog.listenAddr.tcp=:514 -syslog.listenAddr.udp=:514|' /etc/systemd/system/victorialogs.service
    systemctl daemon-reload
    systemctl restart victorialogs
    msg_ok "Enabled Syslog Ingestion (TCP/UDP 514)"
  fi

  if check_for_gh_release "victorialogs" "VictoriaMetrics/VictoriaLogs"; then
    msg_info "Stopping Service"
    systemctl stop victorialogs
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "victorialogs" "VictoriaMetrics/VictoriaLogs" "prebuild" "latest" "/opt/victorialogs" "victoria-logs-linux-$(arch_resolve amd64 arm64)-v*[0-9].tar.gz"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "vlutils" "VictoriaMetrics/VictoriaLogs" "prebuild" "latest" "/opt/vlutils" "vlutils-linux-$(arch_resolve amd64 arm64)-v*[0-9].tar.gz"

    msg_info "Starting Service"
    systemctl start victorialogs
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:9428${CL}"
echo -e "${INFO}${YW}Syslog ingestion (TCP/UDP):${CL}"
echo -e "${GATEWAY}${BGN}${IP}:514${CL}"
