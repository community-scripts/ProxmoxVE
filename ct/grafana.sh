#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://grafana.com/

APP="Grafana"
var_tags="${var_tags:-monitoring;visualization}"
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
  var_disk="${var_disk:-2}"
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
  if ! dpkg -s grafana >/dev/null 2>&1; then
    msg_error "No ${APP} Installation Found!"
    exit 233
  fi

  if [[ -f /etc/apt/sources.list.d/grafana.list ]] || [[ ! -f /etc/apt/sources.list.d/grafana.sources ]]; then
    setup_deb822_repo \
      "grafana" \
      "https://apt.grafana.com/gpg.key" \
      "https://apt.grafana.com" \
      "stable" \
      "main"
  fi

  msg_info "Updating Grafana LXC"
  $STD apt update
  $STD apt --only-upgrade install -y grafana
  msg_ok "Updated successfully!"
}

update_alpine() {
  LXCIP=$(ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)

  CHOICE=$(msg_menu "Grafana Update Options" \
    "1" "Check for Grafana Updates" \
    "2" "Allow 0.0.0.0 for listening" \
    "3" "Allow only ${LXCIP} for listening")

  case $CHOICE in
  1)
    $STD apk -U upgrade
    msg_ok "Updated successfully!"
    exit
    ;;
  2)
    sed -i -e "s/cfg:server.http_addr=.*/cfg:server.http_addr=0.0.0.0/g" /etc/conf.d/grafana
    service grafana restart
    msg_ok "Allowed listening on all interfaces!"
    exit
    ;;
  3)
    sed -i -e "s/cfg:server.http_addr=.*/cfg:server.http_addr=$LXCIP/g" /etc/conf.d/grafana
    service grafana restart
    msg_ok "Allowed listening only on ${LXCIP}!"
    exit
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
