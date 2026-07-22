#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Fabian Pulch (fpulch)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/paperclipai/paperclip

APP="Paperclip"
var_tags="${var_tags:-ai;automation;dev-tools}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/paperclip-ai ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "paperclip-ai" "paperclipai/paperclip"; then
    msg_info "Stopping Service"
    systemctl stop paperclip
    msg_ok "Stopped Service"

    create_backup /opt/paperclip-ai/.env

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "paperclip-ai" "paperclipai/paperclip" "tarball"

    restore_backup

    msg_info "Rebuilding Paperclip"
    cd /opt/paperclip-ai
    export HUSKY=0
    export NODE_OPTIONS="--max-old-space-size=8192"
    $STD pnpm install --frozen-lockfile
    $STD pnpm build
    unset NODE_OPTIONS
    msg_ok "Rebuilt Paperclip"

    msg_info "Updating Agent CLIs"
    $STD npm install -g \
      @anthropic-ai/claude-code@latest \
      @openai/codex@latest
    msg_ok "Updated Agent CLIs"

    msg_info "Running Database Migrations"
    set -a && source /opt/paperclip-ai/.env && set +a
    $STD pnpm db:migrate
    msg_ok "Ran Database Migrations"

    msg_info "Starting Service"
    systemctl start paperclip
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
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:3100${CL}"
