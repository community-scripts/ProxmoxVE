#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://forgejo.org/

APP="Forgejo"
var_tags="${var_tags:-git}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"
if [[ -z "${var_os:-}" ]] && command -v pveversion >/dev/null 2>&1; then
  var_os=$(msg_menu "Choose the container OS" \
    "debian" "Debian 13" \
    "alpine" "Alpine (smaller footprint)")
fi

if [[ "${var_os:-}" == "alpine" ]]; then
  var_cpu="${var_cpu:-1}"
  var_ram="${var_ram:-256}"
  var_disk="${var_disk:-1}"
  var_version="${var_version:-3.24}"
else
  var_cpu="${var_cpu:-2}"
  var_ram="${var_ram:-2048}"
  var_disk="${var_disk:-10}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -d /opt/forgejo ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_codeberg_release "forgejo" "forgejo/forgejo"; then
    msg_info "Stopping Service"
    systemctl stop forgejo
    msg_ok "Stopped Service"

    fetch_and_deploy_codeberg_release "forgejo" "forgejo/forgejo" "singlefile" "latest" "/opt/forgejo" "forgejo-*-linux-$(arch_resolve)"
    ln -sf /opt/forgejo/forgejo /usr/local/bin/forgejo

    if grep -q "GITEA_WORK_DIR" /etc/systemd/system/forgejo.service; then
      msg_info "Updating Service File"
      sed -i "s/GITEA_WORK_DIR/FORGEJO_WORK_DIR/g" /etc/systemd/system/forgejo.service
      systemctl daemon-reload
      msg_ok "Updated Service File"
    fi

    msg_info "Starting Service"
    systemctl start forgejo
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at the latest version."
  fi
}

update_alpine() {
  msg_info "Updating Alpine Packages"
  $STD apk -U upgrade
  msg_ok "Updated Alpine Packages"

  msg_info "Updating Forgejo"
  $STD apk upgrade forgejo
  msg_ok "Updated Forgejo"

  msg_info "Restarting Forgejo"
  $STD rc-service forgejo restart
  msg_ok "Restarted Forgejo"
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
echo -e "${GATEWAY}${BGN}http://${IP}:3000${CL}"
