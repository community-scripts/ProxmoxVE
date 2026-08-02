#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck | Co-Author: havardthom
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cockpit-project/cockpit

APP="Cockpit"
var_tags="${var_tags:-monitoring;network}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /etc/cockpit ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating ${APP} LXC"
  $STD apt update
  $STD apt -y upgrade
  msg_ok "Updated ${APP} LXC"

  if [[ ! -f /etc/apt/sources.list.d/45drives.sources ]]; then
    [[ "$(arch_resolve)" == "arm64" ]] || read -r -p "Would you like to install 45Drives' cockpit-file-sharing, cockpit-identities, and cockpit-navigator now? <y/N> " prompt
    if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
      msg_info "Installing 45Drives' cockpit extensions"
      setup_deb822_repo "45drives" \
        "https://repo.45drives.com/key/gpg.asc" \
        "https://repo.45drives.com/enterprise/debian" \
        "$(get_os_info codename)" \
        "main" \
        "amd64"
      $STD apt install -y cockpit-file-sharing cockpit-identities cockpit-navigator
      msg_ok "Installed 45Drives' cockpit extensions"
    fi
  fi

  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:9090${CL}"
