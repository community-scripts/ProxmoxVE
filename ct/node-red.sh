#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nodered.org/ | Github: https://github.com/node-red/node-red

APP="Node-Red"
var_tags="${var_tags:-automation}"
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
  var_disk="${var_disk:-4}"
  var_version="${var_version:-13}"
fi

header_info "$APP"
variables
color
catch_errors

update_deb_based() {
  if [[ ! -d /root/.node-red ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  UPD=$(msg_menu "Node-Red Update Options" \
    "1" "Update ${APP}" \
    "2" "Install Themes")
  if [ "$UPD" == "1" ]; then
    NODE_VERSION="22" setup_nodejs

    msg_info "Stopping Service"
    systemctl stop nodered
    msg_ok "Stopped Service"

    msg_info "Updating Node-Red"
    $STD npm install -g node-red
    msg_ok "Updated Node-Red"

    msg_info "Starting Service"
    systemctl start nodered
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
    exit
  fi
  if [ "$UPD" == "2" ]; then
    THEME=$(msg_menu "Node-Red Themes" \
      "midnight-red" "Midnight Red (default)" \
      "aurora" "Aurora" \
      "cobalt2" "Cobalt2" \
      "dark" "Dark" \
      "dracula" "Dracula" \
      "espresso-libre" "Espresso Libre" \
      "github-dark" "GitHub Dark" \
      "github-dark-default" "GitHub Dark Default" \
      "github-dark-dimmed" "GitHub Dark Dimmed" \
      "monoindustrial" "Monoindustrial" \
      "monokai" "Monokai" \
      "monokai-dimmed" "Monokai Dimmed" \
      "noctis" "Noctis" \
      "oceanic-next" "Oceanic Next" \
      "oled" "OLED" \
      "one-dark-pro" "One Dark Pro" \
      "one-dark-pro-darker" "One Dark Pro Darker" \
      "solarized-dark" "Solarized Dark" \
      "solarized-light" "Solarized Light" \
      "tokyo-night" "Tokyo Night" \
      "tokyo-night-light" "Tokyo Night Light" \
      "tokyo-night-storm" "Tokyo Night Storm" \
      "totallyinformation" "TotallyInformation" \
      "zenburn" "Zenburn")
    header_info
    msg_info "Installing ${THEME} Theme"
    cd /root/.node-red
    sed -i 's|// theme: ".*",|theme: "",|g' /root/.node-red/settings.js
    $STD npm install @node-red-contrib-themes/theme-collection
    sed -i "{s/theme: ".*"/theme: '${THEME}',/g}" /root/.node-red/settings.js
    systemctl restart nodered
    msg_ok "Installed ${THEME} Theme"
    exit
  fi
}

update_alpine() {
  msg_info "Updating Alpine Packages"
  $STD apk -U upgrade
  msg_ok "Updated Alpine Packages"

  msg_info "Updating Node.js and npm"
  $STD apk upgrade nodejs npm
  msg_ok "Updated Node.js and npm"

  msg_info "Updating Node-RED"
  $STD npm install -g node-red
  msg_ok "Updated Node-RED"

  msg_info "Restarting Node-RED"
  $STD rc-service nodered restart
  msg_ok "Restarted Node-RED"
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
echo -e "${GATEWAY}${BGN}http://${IP}:1880${CL}"
