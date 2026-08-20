#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://caddyserver.com/ | Github: https://github.com/caddyserver/caddy

APP="Caddy"
var_tags="${var_tags:-webserver}"
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
  var_disk="${var_disk:-3}"
  var_version="${var_version:-3.24}"
else
  var_ram="${var_ram:-512}"
  var_disk="${var_disk:-6}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -d /etc/caddy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating Caddy LXC"
  $STD apt update
  $STD apt upgrade -y
  msg_ok "Updated Caddy LXC"

  if command -v xcaddy >/dev/null 2>&1; then
    if check_for_gh_release "xcaddy" "caddyserver/xcaddy"; then
      setup_go
      fetch_and_deploy_gh_release "xcaddy" "caddyserver/xcaddy" "binary"

      msg_info "Updating xCaddy"
      $STD xcaddy build
      msg_ok "Updated xCaddy"
    fi
  fi
  msg_ok "Updated successfully!"
}

update_alpine() {
  if [[ ! -d /etc/caddy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating $APP LXC"
  $STD apk -U upgrade
  msg_ok "Updated $APP LXC"

  msg_info "Restarting Caddy"
  rc-service caddy restart
  msg_ok "Restarted Caddy"
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
echo -e "${GATEWAY}${BGN}http://${IP}:80${CL}"
