#!/usr/bin/env bash
COMMUNITY_SCRIPTS_URL="${COMMUNITY_SCRIPTS_URL:-https://raw.githubusercontent.com/Heretek-AI/ProxmoxVE/refs/heads/main}"
source <(curl -fsSL "${COMMUNITY_SCRIPTS_URL}"/misc/build.func)
# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/infiniflow/ragflow

APP="RAGFlow"
var_tags="${var_tags:-ai;rag;llm;knowledge-base}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-16384}"
var_disk="${var_disk:-50}"
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

  if [[ ! -d /opt/ragflow ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "ragflow" "infiniflow/ragflow"; then
    msg_info "Stopping Services"
    systemctl stop ragflow-task-executor || true
    systemctl stop ragflow-server || true
    msg_ok "Stopped Services"

    msg_info "Backing up Data"
    cp -r /opt/ragflow/conf /opt/ragflow_conf_backup
    cp -r /opt/ragflow/data /opt/ragflow_data_backup 2>/dev/null || true
    cp /opt/ragflow/.env /opt/ragflow_env_backup 2>/dev/null || true
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ragflow" "infiniflow/ragflow" "tarball" "latest" "/opt/ragflow"

    msg_info "Reinstalling Python Dependencies"
    cd /opt/ragflow || exit
    export UV_SYSTEM_PYTHON=1
    $STD /usr/local/bin/uv sync --python 3.12 --frozen --index-strategy unsafe-best-match
    $STD /usr/local/bin/uv run download_deps.py
    msg_ok "Reinstalled Python Dependencies"

    msg_info "Rebuilding Frontend"
    cd /opt/ragflow/web || exit
    $STD npm install
    $STD npm run build
    cp -r /opt/ragflow/web/dist/* /var/www/ragflow/
    msg_ok "Rebuilt Frontend"

    msg_info "Restoring Configuration"
    cp -r /opt/ragflow_conf_backup/. /opt/ragflow/conf/
    cp -r /opt/ragflow_data_backup/. /opt/ragflow/data/ 2>/dev/null || true
    cp /opt/ragflow_env_backup /opt/ragflow/.env 2>/dev/null || true
    rm -rf /opt/ragflow_conf_backup /opt/ragflow_data_backup /opt/ragflow_env_backup
    msg_ok "Restored Configuration"

    msg_info "Starting Services"
    systemctl start ragflow-server
    sleep 5
    systemctl start ragflow-task-executor
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80${CL}"
echo -e "${INFO}${YW} API endpoint: http://${IP}:9380${CL}"
