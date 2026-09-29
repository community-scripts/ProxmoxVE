#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/glanceapp/glance

APP="Glance"
var_tags="${var_tags:-dashboard}"
var_cpu="${var_cpu:-1}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine 3.24 (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_ram="${var_ram:-128}"
  var_disk="${var_disk:-1}"
  var_version="${var_version:-3.24}"
else
  var_ram="${var_ram:-512}"
  var_disk="${var_disk:-2}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -f /etc/systemd/system/glance.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ ! -d /opt/glance_data ]]; then
    msg_info "Creating config directory"
    mkdir -p /opt/glance_data/
    cp /opt/glance/*.yml /opt/glance_data/
    sed -i 's|/opt/glance/glance\.yml|/opt/glance_data/glance.yml|' /etc/systemd/system/glance.service
    systemctl daemon-reload
    msg_ok "Created config directory"
  fi

  if check_for_gh_release "glance" "glanceapp/glance"; then
    msg_info "Stopping Service"
    systemctl stop glance
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "glance" "glanceapp/glance" "prebuild" "latest" "/opt/glance" "glance-linux-$(arch_resolve).tar.gz"

    msg_info "Starting Service"
    systemctl start glance
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

update_alpine() {
  if [[ ! -f /etc/init.d/glance ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ ! -d /opt/glance_data ]]; then
    msg_info "Creating config directory"
    mkdir -p /opt/glance_data/
    cp /opt/glance/*.yml /opt/glance_data/
    sed -i 's|/opt/glance/glance\.yml|/opt/glance_data/glance.yml|' /etc/init.d/glance
    rc-service glance restart
    msg_ok "Created config directory"
  fi

  if check_for_gh_release "glance" "glanceapp/glance"; then
    msg_info "Stopping Service"
    rc-service glance stop
    msg_ok "Stopped Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "glance" "glanceapp/glance" "prebuild" "latest" "/opt/glance" "glance-linux-$(arch_resolve).tar.gz"

    msg_info "Starting Service"
    rc-service glance start
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  run_os_update
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
