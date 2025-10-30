#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ntfy.sh/

APP="ntfy"
var_tags="${var_tags:-notification}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /etc/ntfy ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if [ -f /etc/apt/keyrings/archive.heckel.io.gpg ]; then
    msg_info "Correcting old Ntfy Repository"
    rm -f /etc/apt/keyrings/archive.heckel.io.gpg
    rm -f /etc/apt/sources.list.d/archive.heckel.io.list
    rm -f /etc/apt/sources.list.d/archive.heckel.io.list.bak
    rm -f /etc/apt/sources.list.d/archive.heckel.io.sources
    curl -fsSL -o /etc/apt/keyrings/ntfy.gpg https://archive.ntfy.sh/apt/keyring.gpg
    cat <<'EOF' >/etc/apt/sources.list.d/ntfy.sources
Types: deb
URIs: https://archive.ntfy.sh/apt/
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/ntfy.gpg
EOF
    msg_ok "Corrected old Ntfy Repository"
  fi

  msg_info "Updating $APP LXC"
  $STD apt update
  $STD apt -y upgrade
  msg_ok "Updated $APP LXC"
  msg_ok "Updated successfully!"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
