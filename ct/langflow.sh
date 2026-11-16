#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/langflow-ai/langflow

APP="Langflow"
var_tags="${var_tags:-ai;llm;agents}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

export var_admin_user="${var_admin_user:-}"
export var_admin_pass="${var_admin_pass:-}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/langflow ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "langflow" "langflow-ai/langflow"; then
    msg_info "Stopping Langflow"
    systemctl stop langflow
    msg_ok "Stopped Langflow"

    PYTHON_VERSION="3.14" USE_UVX="YES" setup_uv

    msg_info "Updating Langflow"
    $STD uv venv --clear --python 3.14 /opt/langflow/.venv
    $STD uv pip install --python /opt/langflow/.venv/bin/python "langflow==${CHECK_UPDATE_RELEASE#v}"
    cat <<EOF >~/.langflow
${CHECK_UPDATE_RELEASE#v}
EOF
    msg_ok "Updated Langflow"

    msg_info "Starting Langflow"
    systemctl start langflow
    msg_ok "Started Langflow"
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
echo -e "${GATEWAY}${BGN}http://${IP}:7860${CL}"
echo -e "${INFO}${YW}Login: LANGFLOW_SUPERUSER and LANGFLOW_SUPERUSER_PASSWORD in /opt/langflow_data/.env (inside the container)${CL}"
