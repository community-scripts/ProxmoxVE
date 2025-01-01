#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://changedetection.io/

# App Default Values
APP="Change Detection"
var_tags="monitoring;crawler"
var_cpu="2"
var_ram="1024"
var_disk="8"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /etc/systemd/system/changedetection.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if ! dpkg -s libjpeg-dev >/dev/null 2>&1; then
    msg_info "Installing Dependencies"
    apt-get update
    apt-get install -y libjpeg-dev
    msg_ok "Updated Dependencies"
  fi

  msg_info "Updating ${APP}"
  pip3 install changedetection.io --upgrade &>/dev/null
  msg_ok "Updated ${APP}"

  msg_info "Updating Playwright"
  pip3 install playwright --upgrade &>/dev/null
  msg_ok "Updated Playwright"

  if [[ -f /etc/systemd/system/browserless.service ]]; then
    msg_info "Updating Browserless (Patience)"
    git -C /opt/browserless/ fetch --all &>/dev/null
    git -C /opt/browserless/ reset --hard origin/main &>/dev/null
    npm update --prefix /opt/browserless &>/dev/null
    /opt/browserless/node_modules/playwright-core/cli.js install --with-deps &>/dev/null
    # Update Chrome separately, as it has to be done with the force option. Otherwise the installation of other browsers will not be done if Chrome is already installed.
    /opt/browserless/node_modules/playwright-core/cli.js install --force chrome &>/dev/null
    /opt/browserless/node_modules/playwright-core/cli.js install chromium firefox webkit &>/dev/null
    npm run build --prefix /opt/browserless &>/dev/null
    npm run build:function --prefix /opt/browserless &>/dev/null
    npm prune production --prefix /opt/browserless &>/dev/null
    systemctl restart browserless
    msg_ok "Updated Browserless"
  else
    msg_error "No Browserless Installation Found!"
  fi

  systemctl restart changedetection
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
