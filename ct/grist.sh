#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Source: https://github.com/gristlabs/grist-core

APP="Grist"
var_tags="${var_tags:-database;spreadsheet}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-6}"
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

  if [[ ! -d /opt/grist ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/gristlabs/grist-core/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then

    msg_info "Stopping ${APP} Service"
    systemctl stop grist
    msg_ok "Stopped ${APP} Service"

    msg_info "Updating ${APP} to v${RELEASE}"

    cd /opt
    rm -rf grist_bak
    mv grist grist_bak
    curl -fsSL "https://github.com/gristlabs/grist-core/archive/refs/tags/v${RELEASE}.zip" -o $(basename "https://github.com/gristlabs/grist-core/archive/refs/tags/v${RELEASE}.zip")
    $STD unzip v$RELEASE.zip
    mv grist-core-${RELEASE} grist

    mkdir -p grist/docs

    cp -n grist_bak/.env grist/.env || true
    cp -r grist_bak/docs/* grist/docs/ || true
    cp grist_bak/grist-sessions.db grist/grist-sessions.db || true
    cp grist_bak/landing.db grist/landing.db || true

    cd grist
    msg_info "Installing Dependencies"
    $STD yarn install
    msg_ok "Installed Dependencies"

    msg_info "Building"
    $STD yarn run build:prod
    msg_ok "Done building"

    msg_info "Installing Python"
    $STD yarn run install:python
    msg_ok "Installed Python"

    echo "${RELEASE}" >/opt/${APP}_version.txt

    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting ${APP} Service"
    systemctl start grist
    msg_ok "Started ${APP} Service"

    msg_info "Cleaning up"
    rm -rf /opt/v$RELEASE.zip
    msg_ok "Cleaned"

    msg_ok "Updated Successfully!\n"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}Grist: http://${IP}:8484${CL}"
