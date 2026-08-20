#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://traefik.io/ | Github: https://github.com/traefik/traefik

APP="Traefik"
var_tags="${var_tags:-proxy}"
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
  if [[ ! -f /etc/systemd/system/traefik.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "traefik" "traefik/traefik"; then
    msg_info "Stopping Service"
    systemctl stop traefik
    msg_ok "Stopped Service"

    fetch_and_deploy_gh_release "traefik" "traefik/traefik" "prebuild" "latest" "/usr/bin" "traefik_v*_linux_$(arch_resolve).tar.gz"

    msg_info "Starting Service"
    systemctl start traefik
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
}

update_alpine() {
  msg_info "Updating Alpine Packages"
  $STD apk -U upgrade
  msg_ok "Updated Alpine Packages"

  msg_info "Updating traefik from edge"
  $STD apk add traefik --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
  msg_ok "Updated traefik"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
