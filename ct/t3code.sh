#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: lukdz
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pingdotgg/t3code

APP="T3Code"
var_tags="${var_tags:-ai;dev-tools}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
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

  if ! command -v t3 >/dev/null 2>&1; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping Service"
  systemctl stop t3code
  msg_ok "Stopped Service"

  msg_info "Updating T3 Code"
  $STD npm install -g t3@latest
  msg_ok "Updated T3 Code"

  msg_info "Configuring T3 Code Service"
  mkdir -p /etc/systemd/system/t3code.service.d
  cat <<EOF >/etc/systemd/system/t3code.service.d/claude.conf
[Service]
# Allow Claude Full access mode as root inside the LXC.
Environment=IS_SANDBOX=1
EOF
  systemctl daemon-reload
  msg_ok "Configured T3 Code Service"

  msg_info "Starting Service"
  systemctl start t3code
  msg_ok "Started Service"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
