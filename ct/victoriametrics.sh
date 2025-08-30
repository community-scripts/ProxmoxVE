#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/VictoriaMetrics/VictoriaMetrics

APP="VictoriaMetrics"
var_tags="${var_tags:-database}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-16}"
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
  if [[ ! -d /opt/victoriametrics ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "victoriametrics" "VictoriaMetrics/VictoriaMetrics"; then
    msg_info "Stopping $APP"
    systemctl stop victoriametrics
    [[ -f /etc/systemd/system/victoriametrics-logs.service ]] && systemctl stop victoriametrics-logs
    msg_ok "Stopped $APP"

    victoriametrics_filename=$(curl -fsSL "https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest" |
      jq -r '.assets[].name' |
      grep -E '^victoria-metrics-linux-amd64-v[0-9.]+\.tar\.gz$')
    vmutils_filename=$(curl -fsSL "https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest" |
      jq -r '.assets[].name' |
      grep -E '^vmutils-linux-amd64-v[0-9.]+\.tar\.gz$')

    fetch_and_deploy_gh_release "victoriametrics" "VictoriaMetrics/VictoriaMetrics" "prebuild" "latest" "/opt/victoriametrics" "$victoriametrics_filename"
    fetch_and_deploy_gh_release "vmutils" "VictoriaMetrics/VictoriaMetrics" "prebuild" "latest" "/opt/victoriametrics" "$vmutils_filename"

    if [[ -f /etc/systemd/system/victoriametrics-logs.service ]]; then
      fetch_and_deploy_gh_release "victorialogs" "VictoriaMetrics/VictoriaLogs" "prebuild" "latest" "/opt/victoriametrics" "victoria-logs-linux-amd64*.tar.gz"
      fetch_and_deploy_gh_release "vlutils" "VictoriaMetrics/VictoriaLogs" "prebuild" "latest" "/opt/victoriametrics" "vlutils-linux-amd64*.tar.gz"
    fi
    chmod +x /opt/victoriametrics/*

    msg_info "Starting $APP"
    systemctl start victoriametrics
    [[ -f /etc/systemd/system/victoriametrics-logs.service ]] && systemctl start victoriametrics-logs
    msg_ok "Started $APP"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8428/vmui${CL}"
