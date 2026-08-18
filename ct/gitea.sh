#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | Co-Author: Rogue-King
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://about.gitea.com/ | Github: https://github.com/go-gitea/gitea

APP="Gitea"
var_tags="${var_tags:-git}"
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
  var_ram="${var_ram:-1024}"
  var_disk="${var_disk:-8}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -f /usr/local/bin/gitea ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if check_for_gh_release "gitea" "go-gitea/gitea"; then
    msg_info "Stopping service"
    systemctl stop gitea
    msg_ok "Service stopped"

    rm -rf /usr/local/bin/gitea
    fetch_and_deploy_gh_release "gitea" "go-gitea/gitea" "singlefile" "latest" "/usr/local/bin" "gitea-*-linux-$(arch_resolve)"
    chmod +x /usr/local/bin/gitea

    msg_info "Starting service"
    systemctl start gitea
    msg_ok "Started service"
    msg_ok "Updated successfully!"
  fi
}

update_alpine() {
  msg_info "Updating Alpine Packages"
  $STD apk -U upgrade
  msg_ok "Updated Alpine Packages"

  msg_info "Updating Gitea"
  apk upgrade gitea
  msg_ok "Updated Gitea"

  msg_info "Restarting Gitea"
  rc-service gitea restart
  msg_ok "Restarted Gitea"
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
