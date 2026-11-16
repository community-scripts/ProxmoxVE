#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bugsink/bugsink

APP="Bugsink"
var_tags="${var_tags:-monitoring;error-tracking;sentry}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

export var_admin_email="${var_admin_email:-}"
export var_admin_pass="${var_admin_pass:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/bugsink ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "bugsink" "bugsink/bugsink"; then
    msg_info "Stopping Bugsink"
    systemctl stop bugsink bugsink-snappea
    msg_ok "Stopped Bugsink"

    PYTHON_VERSION="3.12" setup_uv

    msg_info "Updating Bugsink"
    $STD uv pip install --upgrade --python /opt/bugsink/.venv/bin/python "bugsink==${CHECK_UPDATE_RELEASE}"
    cd /opt/bugsink_data
    $STD /opt/bugsink/.venv/bin/bugsink-manage migrate
    $STD /opt/bugsink/.venv/bin/bugsink-manage migrate snappea --database=snappea
    cat <<EOF >~/.bugsink
${CHECK_UPDATE_RELEASE}
EOF
    msg_ok "Updated Bugsink"

    msg_info "Starting Bugsink"
    systemctl start bugsink bugsink-snappea
    msg_ok "Started Bugsink"
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
echo -e "${GATEWAY}${BGN}http://${IP}:8000${CL}"
echo -e "${INFO}${YW}Admin login: /opt/bugsink_data/.env (inside the container)${CL}"
