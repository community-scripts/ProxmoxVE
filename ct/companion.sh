#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/glabutis/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: glabutis
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bitfocus/companion

APP="Companion"
var_tags="${var_tags:-automation;media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"
var_keyctl="${var_keyctl:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/companion ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  CURRENT=""
  [[ -f /opt/companion-config/version.txt ]] && CURRENT=$(cat /opt/companion-config/version.txt)

  RELEASE_JSON=$(curl -fsSL "https://api.bitfocus.io/v1/product/companion/packages?limit=20")
  LATEST=$(echo "$RELEASE_JSON" | grep -o '"version":"[^"]*","target":"linux-tgz"' | head -1 | awk -F'"' '{print $4}')

  if [[ "$CURRENT" == "$LATEST" ]]; then
    msg_ok "Already running Bitfocus Companion ${LATEST} — no update needed."
    exit
  fi

  ASSET_URL=$(echo "$RELEASE_JSON" | grep -o '"uri":"[^"]*linux-x64[^"]*"' | head -1 | awk -F'"' '{print $4}')

  msg_info "Updating ${APP} to ${LATEST}"
  systemctl stop companion
  rm -rf /opt/companion
  mkdir -p /opt/companion
  curl -fsSL "$ASSET_URL" -o /tmp/companion.tar.gz
  tar -xzf /tmp/companion.tar.gz -C /opt/companion --strip-components=1
  rm -f /tmp/companion.tar.gz
  chown -R companion:companion /opt/companion
  systemctl start companion
  echo "${LATEST}" >/opt/companion-config/version.txt
  msg_ok "Updated ${APP} to ${LATEST}"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
