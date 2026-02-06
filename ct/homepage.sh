#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gethomepage.dev/

APP="Homepage"
var_tags="${var_tags:-dashboard}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-6}"
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
  if [[ ! -d /opt/homepage ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs
  ensure_dependencies jq

  if check_for_gh_release "homepage" "gethomepage/homepage"; then
    msg_info "Stopping service"
    systemctl stop homepage
    msg_ok "Stopped service"

    msg_info "Creating Backup"
    cp /opt/homepage/.env /opt/homepage.env
    cp -r /opt/homepage/config /opt/homepage_config_backup
    [[ -d /opt/homepage/public/images ]] && cp -r /opt/homepage/public/images /opt/homepage_images_backup
    [[ -d /opt/homepage/public/icons ]] && cp -r /opt/homepage/public/icons /opt/homepage_icons_backup
    msg_ok "Created Backup"
    
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "homepage" "gethomepage/homepage" "tarball"
    
    msg_info "Restoring Backup"
    mv /opt/homepage.env /opt/homepage
    rm -rf /opt/homepage/config
    mv /opt/homepage_config_backup /opt/homepage/config
    msg_ok "Restored Backup"

    msg_info "Updating Homepage (Patience)"
    RELEASE=$(get_latest_github_release "gethomepage/homepage")
    cd /opt/homepage
    $STD pnpm install
    $STD pnpm update --no-save caniuse-lite
    export NEXT_PUBLIC_VERSION="v$RELEASE"
    export NEXT_PUBLIC_REVISION="source"
    export NEXT_PUBLIC_BUILDTIME=$(curl -fsSL https://api.github.com/repos/gethomepage/homepage/releases/latest | jq -r '.published_at')
    export NEXT_TELEMETRY_DISABLED=1
    $STD pnpm build
    [[ -d /opt/homepage_images_backup ]] && mv /opt/homepage_images_backup /opt/homepage/public/images
    [[ -d /opt/homepage_icons_backup ]] && mv /opt/homepage_icons_backup /opt/homepage/public/icons
    msg_ok "Updated Homepage"

    msg_info "Starting service"
    systemctl start homepage
    msg_ok "Started service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
