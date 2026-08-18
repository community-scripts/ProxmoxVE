#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: GoldenSpringness
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/orhun/rustypaste

APP="rustypaste"
var_tags="${var_tags:-pastebin;storage}"
var_cpu="${var_cpu:-1}"
var_arm64="${var_arm64:-no}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_ram="${var_ram:-256}"
  var_disk="${var_disk:-4}"
  var_version="${var_version:-3.24}"
else
  var_ram="${var_ram:-1024}"
  var_disk="${var_disk:-20}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -f /opt/rustypaste/rustypaste ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "rustypaste" "orhun/rustypaste"; then
    msg_info "Stopping Services"
    systemctl stop rustypaste
    msg_ok "Stopped Services"

    create_backup /opt/rustypaste/upload /opt/rustypaste/config.toml

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "rustypaste" "orhun/rustypaste" "prebuild" "latest" "/opt/rustypaste" "*x86_64-unknown-linux-gnu.tar.gz"

    restore_backup

    msg_info "Starting Services"
    systemctl start rustypaste
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi

  if check_for_gh_release "rustypaste-cli" "orhun/rustypaste-cli"; then
    fetch_and_deploy_gh_release "rustypaste-cli" "orhun/rustypaste-cli" "prebuild" "latest" "/usr/local/bin" "*x86_64-unknown-linux-gnu.tar.gz"
  fi
}

update_alpine() {
  if ! apk info -e rustypaste >/dev/null 2>&1; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating RustyPaste"
  $STD apk update
  $STD apk upgrade rustypaste --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
  msg_ok "Updated RustyPaste"

  msg_info "Restarting Services"
  $STD rc-service rustypaste restart
  msg_ok "Restarted Services"
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
echo -e "${CREATING}${GN}rustypaste setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
