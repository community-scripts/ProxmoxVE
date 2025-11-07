#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pangolin.net/

APP="Pangolin"
var_tags="${var_tags:-proxy}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-5}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_tun="${var_tun:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/pangolin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "pangolin" "fosrl/pangolin"; then
    msg_info "Stopping Service"
    systemctl stop pangolin
    systemctl stop gerbil
    msg_info "Service stopped"

    msg_info "Creating backup"
    tar -czf /opt/pangolin_config_backup.tar.gz -C /opt/pangolin config
    msg_ok "Created backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "pangolin" "fosrl/pangolin" "tarball"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "gerbil" "fosrl/gerbil" "singlefile" "latest" "/usr/bin" "gerbil_linux_amd64"

    msg_info "Updating Pangolin"
    cd /opt/pangolin
    $STD npm ci
    $STD npm run set:sqlite
    $STD npm run set:oss
    rm -rf server/private
    $STD npm run build:sqlite
    $STD npm run build:cli
    cp -R .next/standalone ./
    chmod +x ./dist/cli.mjs
    cp server/db/names.json ./dist/names.json
    msg_ok "Updated Pangolin"

    msg_info "Restoring config"
    tar -xzf /opt/pangolin_config_backup.tar.gz -C /opt/pangolin --overwrite
    rm -f /opt/pangolin_config_backup.tar.gz
    msg_ok "Restored config"

    msg_info "Starting Services"
    systemctl start pangolin
    systemctl start gerbil
    msg_ok "Started Services"
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
echo -e "${TAB}${GATEWAY}${BGN}https://<YOUR_PANGOLIN_URL>${CL}"
