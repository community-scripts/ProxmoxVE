#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/muety/wakapi | Website: https://wakapi.dev

APP="Wakapi"
var_tags="${var_tags:-productivity;analytics}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -f /etc/systemd/system/wakapi.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  if check_for_gh_release "wakapi" "muety/wakapi"; then
    msg_info "Stopping Service"
    systemctl stop wakapi
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration and Data"
    cp /opt/wakapi/config.yml /tmp/wakapi_config_backup.yml 2>/dev/null || true
    msg_ok "Backed up Configuration"

    msg_info "Updating Wakapi"
    fetch_and_deploy_gh_release "wakapi" "muety/wakapi" "prebuild" "latest" "/opt/wakapi/bin" "wakapi_linux_*.zip"
    msg_ok "Updated Wakapi"

    msg_info "Restoring Configuration"
    cp /tmp/wakapi_config_backup.yml /opt/wakapi/config.yml 2>/dev/null || true
    rm -f /tmp/wakapi_config_backup.yml
    msg_ok "Restored Configuration"

    msg_info "Starting Service"
    systemctl start wakapi
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
