#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Dictionarry-Hub/profilarr

APP="Profilarr"
var_tags="${var_tags:-arr;radarr;sonarr;config}"
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

  if [[ ! -d /opt/profilarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "profilarr" "Dictionarry-Hub/profilarr"; then
    msg_info "Stopping Service"
    systemctl stop profilarr
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    if [[ -d /config ]]; then
      cp -r /config /opt/profilarr_config_backup
    fi
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "profilarr" "Dictionarry-Hub/profilarr" "tarball"

    msg_info "Installing Python Dependencies"
    cd /opt/profilarr/backend
    $STD uv venv /opt/profilarr/backend/.venv
    sed 's/==/>=/g' requirements.txt >requirements-relaxed.txt
    $STD uv pip install --python /opt/profilarr/backend/.venv/bin/python -r requirements-relaxed.txt
    rm -f requirements-relaxed.txt
    msg_ok "Installed Python Dependencies"

    msg_info "Building Frontend"
    if [[ -d /opt/profilarr/frontend ]]; then
      cd /opt/profilarr/frontend
      $STD npm install
      $STD npm run build
      cp -r dist /opt/profilarr/backend/app/static
    fi
    msg_ok "Built Frontend"

    msg_info "Restoring Data"
    if [[ -d /opt/profilarr_config_backup ]]; then
      mkdir -p /config
      cp -r /opt/profilarr_config_backup/. /config/
      rm -rf /opt/profilarr_config_backup
    fi
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start profilarr
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6868${CL}"
