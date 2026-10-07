#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rustdesk/rustdesk-server

APP="RustDesk Server"
var_tags="${var_tags:-remote-desktop}"
var_cpu="${var_cpu:-1}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_ram="${var_ram:-512}"
  var_disk="${var_disk:-3}"
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
  if [[ ! -x /usr/bin/hbbr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "rustdesk-hbbs" "lejianwen/rustdesk-server"; then
    msg_info "Stopping Service"
    systemctl stop rustdesk-hbbr
    systemctl stop rustdesk-hbbs
    if [[ -f /lib/systemd/system/rustdesk-api.service ]]; then
      systemctl stop rustdesk-api
    fi
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "rustdesk-hbbr" "lejianwen/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-hbbr*$(arch_resolve).deb"
    fetch_and_deploy_gh_release "rustdesk-hbbs" "lejianwen/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-hbbs*$(arch_resolve).deb"
    fetch_and_deploy_gh_release "rustdesk-utils" "lejianwen/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-utils*$(arch_resolve).deb"
    fetch_and_deploy_gh_release "rustdesk-api" "lejianwen/rustdesk-api" "binary" "latest" "/opt/rustdesk" "rustdesk-api-server*$(arch_resolve).deb"

    msg_info "Starting services"
    systemctl start -q rustdesk-*
    msg_ok "Services started"

    msg_ok "Updated successfully!"
  fi
}

update_alpine() {
  if [[ ! -d /opt/rustdesk-server ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "rustdesk-server" "lejianwen/rustdesk-server"; then
    msg_info "Stopping RustDesk Server"
    $STD apk -U upgrade
    $STD service rustdesk-server-hbbs stop
    $STD service rustdesk-server-hbbr stop
    msg_ok "Stopped RustDesk Server"

    fetch_and_deploy_gh_release "rustdesk-server" "lejianwen/rustdesk-server" "prebuild" "latest" "/opt/rustdesk-server" "rustdesk-server-linux-$(arch_resolve "amd64" "arm64v8").zip"

    msg_info "Starting RustDesk Server"
    $STD service rustdesk-server-hbbs start
    $STD service rustdesk-server-hbbr start
    msg_ok "Started RustDesk Server"
  fi
  if check_for_gh_release "rustdesk-api" "lejianwen/rustdesk-api"; then
    msg_info "Stopping RustDesk API"
    $STD service rustdesk-api stop
    msg_ok "Stopped RustDesk API"

    fetch_and_deploy_gh_release "rustdesk-api" "lejianwen/rustdesk-api" "prebuild" "latest" "/opt/rustdesk-api" "linux-$(arch_resolve).tar.gz"

    msg_info "Starting RustDesk API"
    $STD service rustdesk-api start
    msg_ok "Started RustDesk API"
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:21114${CL}"
