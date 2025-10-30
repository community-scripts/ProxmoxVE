#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.emqx.com/en

APP="EMQX"
var_tags="${var_tags:-mqtt}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  RELEASE=$(curl -fsSL https://www.emqx.com/en/downloads/enterprise | grep -oP '/en/downloads/enterprise/v\K[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n1)
  if [[ "$RELEASE" != "$(cat ~/.emqx 2>/dev/null)" ]] || [[ ! -f ~/.emqx ]]; then
    msg_info "Stopping EMQX"
    systemctl stop emqx
    msg_ok "Stopped EMQX"

    msg_info "Removing old EMQX"
    if dpkg -l | grep -q "^ii\s\+emqx\s"; then
      $STD apt-get remove --purge -y emqx
    elif dpkg -l | grep -q "^ii\s\+emqx-enterprise\s"; then
      $STD apt-get remove --purge -y emqx-enterprise
    else
      msg_ok "No old EMQX package found"
    fi
    msg_ok "Removed old EMQX"

    msg_info "Downloading EMQX v${RELEASE}"
    DEB_FILE="/tmp/emqx-enterprise-${RELEASE}-debian12-amd64.deb"
    curl -fsSL -o "$DEB_FILE" "https://www.emqx.com/en/downloads/enterprise/v${RELEASE}/emqx-enterprise-${RELEASE}-debian12-amd64.deb"
    msg_ok "Downloaded EMQX"

    msg_info "Installing EMQX"
    $STD apt-get install -y "$DEB_FILE"
    msg_ok "Installed EMQX v${RELEASE}"

    msg_info "Starting EMQX"
    systemctl start emqx
    echo "$RELEASE" >~/.emqx
    msg_ok "Started EMQX"

    msg_info "Cleaning Up"
    rm -f "$DEB_FILE"
    msg_ok "Cleanup Completed"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. EMQX is already at v${RELEASE}"
  fi

  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:18083${CL}"
