#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
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
    msg_info "Stopped Service"

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

  APIRELEASE=$(curl -s https://api.github.com/repos/lejianwen/rustdesk-api/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  RELEASE=$(curl -s https://api.github.com/repos/lejianwen/rustdesk-server/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [ "${RELEASE}" != "$(cat ~/.rustdesk-server 2>/dev/null)" ] || [ ! -f ~/.rustdesk-server ]; then
    msg_info "Updating RustDesk Server to v${RELEASE}"
    $STD apk -U upgrade
    $STD service rustdesk-server-hbbs stop
    $STD service rustdesk-server-hbbr stop
    temp_file1=$(mktemp)
    ARCH=$(arch_resolve "amd64" "arm64v8")
    curl -fsSL "https://github.com/lejianwen/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-linux-${ARCH}.zip" -o "$temp_file1"
    $STD unzip "$temp_file1"
    cp -r "$ARCH"/* /opt/rustdesk-server/
    echo "${RELEASE}" >~/.rustdesk-server
    $STD service rustdesk-server-hbbs start
    $STD service rustdesk-server-hbbr start
    rm -rf "$ARCH"
    rm -f "$temp_file1"
    msg_ok "Updated RustDesk Server"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  if [ "${APIRELEASE}" != "$(cat ~/.rustdesk-api)" ] || [ ! -f ~/.rustdesk-api ]; then
    msg_info "Updating RustDesk API to v${APIRELEASE}"
    $STD service rustdesk-api stop
    temp_file2=$(mktemp)
    curl -fsSL "https://github.com/lejianwen/rustdesk-api/releases/download/v${APIRELEASE}/linux-$(arch_resolve).tar.gz" -o "$temp_file2"
    $STD tar zxvf "$temp_file2"
    cp -r release/* /opt/rustdesk-api
    echo "${APIRELEASE}" >~/.rustdesk-api
    $STD service rustdesk-api start
    rm -rf release
    rm -f "$temp_file2"
    msg_ok "Updated RustDesk API"
  else
    msg_ok "No update required. RustDesk API is already at v${APIRELEASE}"
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
