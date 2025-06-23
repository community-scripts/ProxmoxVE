#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://changedetection.io/

APP="Change Detection"
var_tags="${var_tags:-monitoring;crawler}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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

  if [[ ! -f /etc/systemd/system/changedetection.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if ! dpkg -s libjpeg-dev >/dev/null 2>&1; then
    msg_info "Installing Dependencies"
    $STD apt-get update
    $STD apt-get install -y libjpeg-dev
    msg_ok "Updated Dependencies"
  fi

  msg_info "Updating ${APP}"
  $STD pip3 install changedetection.io --upgrade
  msg_ok "Updated ${APP}"

  msg_info "Updating Playwright"
  $STD pip3 install playwright --upgrade
  msg_ok "Updated Playwright"

  if [[ -f /etc/systemd/system/browserless.service ]]; then
    msg_info "Updating Browserless (Patience)"
    $STD git -C /opt/browserless/ fetch --all
    $STD git -C /opt/browserless/ reset --hard origin/main
    $STD npm update --prefix /opt/browserless
    $STD /opt/browserless/node_modules/playwright-core/cli.js install --with-deps
    # Update Chrome separately, as it has to be done with the force option. Otherwise the installation of other browsers will not be done if Chrome is already installed.
    $STD /opt/browserless/node_modules/playwright-core/cli.js install --force chrome
    $STD /opt/browserless/node_modules/playwright-core/cli.js install --force msedge
    $STD /opt/browserless/node_modules/playwright-core/cli.js install chromium firefox webkit
    $STD npm run build --prefix /opt/browserless
    $STD npm run build:function --prefix /opt/browserless
    $STD npm prune production --prefix /opt/browserless
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
