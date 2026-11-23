#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Chris Moriarty (cwmoriarty)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/philippe44/AirConnect

APP="AirConnect"
var_tags="${var_tags:-airplay;audio;streaming}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
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

  if [[ ! -d /opt/airconnect ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "airconnect" "philippe44/AirConnect"; then
    msg_info "Stopping AirConnect"
    if systemctl is-active --quiet airupnp; then systemctl stop airupnp; fi
    if systemctl is-active --quiet aircast; then systemctl stop aircast; fi
    msg_ok "Stopped AirConnect"

    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP="airupnp.xml aircast.xml" fetch_and_deploy_gh_release "airconnect" "philippe44/AirConnect" "prebuild" "latest" "/opt/airconnect" "AirConnect-*.zip"

    msg_info "Configuring AirConnect"
    ARCH=$(arch_resolve x86_64 aarch64)
    chmod +x "/opt/airconnect/airupnp-linux-${ARCH}" "/opt/airconnect/aircast-linux-${ARCH}"
    ln -sf "/opt/airconnect/airupnp-linux-${ARCH}" /opt/airconnect/airupnp
    ln -sf "/opt/airconnect/aircast-linux-${ARCH}" /opt/airconnect/aircast
    find /opt/airconnect -maxdepth 1 -type f ! -name "airupnp-linux-${ARCH}" ! -name "aircast-linux-${ARCH}" ! -name "*.xml" -delete
    msg_ok "Configured AirConnect"

    msg_info "Starting AirConnect"
    if systemctl is-enabled --quiet airupnp; then systemctl start airupnp; fi
    if systemctl is-enabled --quiet aircast; then systemctl start aircast; fi
    msg_ok "Started AirConnect"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}AirConnect is running and bridging AirPlay to discovered players:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}airupnp${CL}  ${YW}(UPnP / Sonos bridge)${CL}"
echo -e "${TAB}${GATEWAY}${BGN}aircast${CL}  ${YW}(Chromecast bridge)${CL}"
echo -e "${INFO}${YW}Ensure your container is on the same LAN subnet as your devices.${CL}"
