#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/storybookjs/storybook

APP="Storybook"
var_tags="${var_tags:-dev-tools;frontend;ui}"
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

  if [[ ! -f /opt/storybook/.projectpath ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  PROJECT_PATH=$(cat /opt/storybook/.projectpath)

  if [[ ! -d "$PROJECT_PATH" ]]; then
    msg_error "Project directory not found: $PROJECT_PATH"
    exit
  fi

  msg_info "Updating Storybook"
  cd "$PROJECT_PATH"
  $STD npx storybook@latest upgrade --yes
  msg_ok "Updated Storybook"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6006${CL}"
