#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: glabutis
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bitfocus/companion

APP="Bitfocus-Companion"
var_tags="${var_tags:-automation;media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
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

  if [[ ! -f /opt/bitfocus-companion/companion_headless.sh ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  RELEASE_JSON=$(curl -fsSL "https://api.bitfocus.io/v1/product/companion/packages?limit=20")
  PACKAGE_JSON=$(echo "$RELEASE_JSON" | jq -c \
    --arg target "linux-$(arch_resolve "tgz" "arm64-tgz")" \
    --arg arch "linux-$(arch_resolve "x64" "arm64")" \
    '(if type == "array" then . else .packages end) | [.[] | select(.target==$target and (.uri | contains($arch)))] | first')
  RELEASE=$(echo "$PACKAGE_JSON" | jq -r '.version // empty')
  ASSET_URL=$(echo "$PACKAGE_JSON" | jq -r '.uri // empty')
  if [[ -z "$RELEASE" || -z "$ASSET_URL" ]]; then
    msg_error "Could not resolve a matching Linux $(arch_resolve "x64" "arm64") Companion package from the Bitfocus API."
    exit 1
  fi

  if [[ "${RELEASE}" == "$(cat ~/.bitfocus-companion 2>/dev/null)" ]]; then
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
    exit
  fi

  msg_info "Stopping ${APP}"
  systemctl stop bitfocus-companion
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP} to v${RELEASE}"
  CLEAN_INSTALL=1 fetch_and_deploy_from_url "$ASSET_URL" "/opt/bitfocus-companion"
  echo "${RELEASE}" >~/.bitfocus-companion
  msg_ok "Updated ${APP} to v${RELEASE}"

  msg_info "Starting ${APP}"
  systemctl start bitfocus-companion
  msg_ok "Started ${APP}"

  msg_ok "Update Successful"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
