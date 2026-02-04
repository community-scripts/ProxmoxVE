#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Crazywolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/guillevc/yubal

APP="Yubal"
var_tags="${var_tags:-music;media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-15}"
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

  if [[ ! -d /opt/yubal ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  ensure_dependencies git

  if check_for_gh_release "yubal" "guillevc/yubal"; then
    msg_info "Stopping Services"
    systemctl stop yubal
    msg_ok "Stopped Services"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "yubal" "guillevc/yubal" "tarball" "latest" "/opt/yubal"

    msg_info "Building Frontend"
    cd /opt/yubal/web
    $STD bun install --frozen-lockfile
    VERSION=$(get_latest_github_release "guillevc/yubal")
    VITE_VERSION=$VERSION VITE_COMMIT_SHA=$VERSION VITE_IS_RELEASE=true $STD bun run build
    msg_ok "Built Frontend"

    msg_info "Installing Python Dependencies"
    cd /opt/yubal
    $STD uv sync --no-dev --frozen
    msg_ok "Installed Python Dependencies"

    msg_info "Starting Services"
    systemctl start yubal
    msg_ok "Started Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
