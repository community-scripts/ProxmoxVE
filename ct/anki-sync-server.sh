#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
# Engine comes from community-scripts/core; this repo only ships the scripts.
# A local core checkout wins (COMMUNITY_SCRIPTS_CORE_DIR, else a sibling ../core),
# so a fork or branch of core can be tested without editing this file.
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.ankiweb.net/sync-server.html

APP="Anki-Sync-Server"
var_tags="${var_tags:-anki;flashcards;sync}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
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

  if [[ ! -f /opt/anki-sync-server/.env ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "anki-sync-server" "ankitects/anki"; then
    msg_info "Stopping Service"
    systemctl stop anki-sync-server
    msg_ok "Stopped Service"

    create_backup /opt/anki-sync-server/.env /opt/anki-sync-server/data

    msg_info "Updating Anki Sync Server"
    $STD uv pip install --python /opt/anki-sync-server/venv/bin/python "anki==$(get_latest_github_release "ankitects/anki")"
    cat <<EOF >~/.anki-sync-server
$(get_latest_github_release "ankitects/anki")
EOF
    msg_ok "Updated Anki Sync Server"

    restore_backup

    msg_info "Starting Service"
    systemctl start anki-sync-server
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
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
echo -e "${INFO}${YW}Credentials are stored in:${CL}"
echo -e "${GATEWAY}${BGN}/opt/anki-sync-server/.env${CL}"
