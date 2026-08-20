#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://redis.io/

APP="Redis"
var_tags="${var_tags:-database}"
var_cpu="${var_cpu:-1}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine 3.24 (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_ram="${var_ram:-256}"
  var_disk="${var_disk:-1}"
  var_version="${var_version:-3.24}"
else
  var_ram="${var_ram:-1024}"
  var_disk="${var_disk:-4}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -f /lib/systemd/system/redis-server.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  msg_info "Updating $APP LXC"
  $STD apt update
  $STD apt upgrade -y
  msg_ok "Updated $APP LXC"
}

update_alpine() {
  if [[ ! -f /etc/init.d/redis ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  LXCIP=$(ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
  CHOICE=$(msg_menu "Redis Management" \
    "1" "Update Redis" \
    "2" "Allow 0.0.0.0 for listening" \
    "3" "Allow only ${LXCIP} for listening")

  case "$CHOICE" in
  1)
    msg_info "Updating Redis"
    $STD apk update
    $STD apk upgrade redis
    rc-service redis restart
    msg_ok "Updated Redis"
    ;;
  2)
    msg_info "Setting Redis to listen on all interfaces"
    sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis.conf
    rc-service redis restart
    msg_ok "Redis now listens on all interfaces"
    ;;
  3)
    msg_info "Setting Redis to listen only on ${LXCIP}"
    sed -i "s/^bind .*/bind ${LXCIP}/" /etc/redis.conf
    rc-service redis restart
    msg_ok "Redis now listens only on ${LXCIP}"
    ;;
  esac
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
echo -e "${INFO}${YW}Access it using the following IP:${CL}"
echo -e "${GATEWAY}${BGN}${IP}:6379${CL}"
