#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.zigbee2mqtt.io/ | Github: https://github.com/Koenkk/zigbee2mqtt

APP="Zigbee2MQTT"
var_tags="${var_tags:-smarthome;zigbee;mqtt}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-5}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/zigbee2mqtt ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "Zigbee2MQTT" "Koenkk/zigbee2mqtt"; then
    NODE_VERSION="24" NODE_MODULE="pnpm@$(curl -fsSL https://raw.githubusercontent.com/Koenkk/zigbee2mqtt/master/package.json | jq -r '.packageManager | split("@")[1]')" setup_nodejs
    msg_info "Stopping Service"
    systemctl stop zigbee2mqtt
    msg_ok "Stopped Service"

    msg_info "Creating Backup"
    ensure_dependencies zstd
    mkdir -p /opt/{backups,z2m_backup}
    BACKUP_VERSION="$(<"$HOME/.zigbee2mqtt")"
    BACKUP_FILE="/opt/backups/${APP}_backup_${BACKUP_VERSION}.tar.zst"
    $STD tar -cf - -C /opt zigbee2mqtt | zstd -q -o "$BACKUP_FILE"
    ls -t /opt/backups/${APP}_backup_*.tar.zst 2>/dev/null | tail -n +6 | xargs -r rm -f
    mv /opt/zigbee2mqtt/data /opt/z2m_backup/data
    msg_ok "Backup Created (${BACKUP_VERSION})"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Zigbee2MQTT" "Koenkk/zigbee2mqtt" "tarball" "latest" "/opt/zigbee2mqtt"

    msg_info "Updating Zigbee2MQTT"
    rm -rf /opt/zigbee2mqtt/data
    mv /opt/z2m_backup/data /opt/zigbee2mqtt
    cd /opt/zigbee2mqtt
    grep -q "^packageImportMethod" ./pnpm-workspace.yaml || echo "packageImportMethod: hardlink" >>./pnpm-workspace.yaml
    $STD pnpm install --frozen-lockfile
    $STD pnpm build
    rm -rf /opt/z2m_backup
    msg_ok "Updated Zigbee2MQTT"

    msg_info "Starting Service"
    systemctl start zigbee2mqtt
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9442${CL}"
