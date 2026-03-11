#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Thiago Canozzo Lahr (tclahr)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/immichFrame/ImmichFrame

APP="ImmichFrame"
var_tags="${var_tags:-photos;slideshow}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -d /opt/immichframe ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "immichframe" "immichFrame/ImmichFrame"; then
    msg_info "Stopping Service"
    systemctl stop immichframe
    msg_ok "Stopped Service"

    msg_info "Backing up Configuration"
    cp -r /opt/immichframe/Config /tmp/immichframe_config.bak
    msg_ok "Backed up Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "immichframe" "immichFrame/ImmichFrame" "tarball" "latest" "/tmp/immichframe"

    msg_info "Setting up ImmichFrame"
    cd /tmp/immichframe
    $STD dotnet publish ImmichFrame.WebApi/ImmichFrame.WebApi.csproj \
      --configuration Release \
      --runtime linux-x64 \
      --self-contained false \
      --output /opt/immichframe

    cd /tmp/immichframe/immichFrame.Web
    $STD npm ci --silent
    $STD npm run build
    rm -rf /opt/immichframe/wwwroot/*
    cp -r build/* /opt/immichframe/wwwroot
    rm -rf /tmp/immichframe
    msg_ok "Setup ImmichFrame"

    msg_info "Restoring Configuration"
    cp -r /tmp/immichframe_config.bak/* /opt/immichframe/Config/
    rm -rf /tmp/immichframe_config.bak
    chown -R immichframe:immichframe /opt/immichframe
    msg_ok "Restored Configuration"


    msg_info "Starting Service"
    systemctl start immichframe
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
