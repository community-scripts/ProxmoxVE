#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.wireguard.com/

APP="Wireguard"
var_tags="${var_tags:-network;vpn}"
var_cpu="${var_cpu:-1}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_ram="${var_ram:-256}"
  var_disk="${var_disk:-1}"
  var_version="${var_version:-3.24}"
else
  var_ram="${var_ram:-512}"
  var_disk="${var_disk:-4}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -d /etc/wireguard ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  ensure_dependencies git

  msg_info "Updating LXC"
  $STD apt update
  $STD apt upgrade -y
  if [[ -d /etc/wgdashboard ]]; then
    sleep 2
    cd /etc/wgdashboard/src
    $STD ./wgd.sh update -y
    $STD ./wgd.sh start
  fi
  msg_ok "Updated LXC"
  msg_ok "Updated successfully!"
}

update_alpine() {
  msg_info "Updating Alpine Packages"
  $STD apk -U upgrade
  msg_ok "Updated Alpine Packages"

  msg_info "update wireguard-tools"
  $STD apk add --no-cache --upgrade wireguard-tools
  msg_ok "wireguard-tools updated"

  if [[ -d /etc/wgdashboard/src ]]; then
    msg_info "update WGDashboard"
    cd /etc/wgdashboard/src
    echo "y" | ./wgd.sh update >/dev/null 2>&1
    $STD ./wgd.sh start
    msg_ok "WGDashboard updated"
  fi
  msg_ok "Updated successfully!"
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
echo -e "${INFO}${YW}Access WGDashboard (if installed) using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:10086${CL}"
