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

  cd /opt/ragflow
  LOCAL_VERSION=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
  REMOTE_VERSION=$(git ls-remote origin HEAD 2>/dev/null | awk '{print $1}' || echo "unknown")

  if [[ "$LOCAL_VERSION" == "$REMOTE_VERSION" ]] || [[ "$REMOTE_VERSION" == "unknown" ]]; then
    if [[ "$REMOTE_VERSION" == "unknown" ]]; then
      msg_info "Unable to check for updates. Checking local version..."
      CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
      msg_info "Current version: ${CURRENT_TAG}"
    fi
    msg_info "No update required. ${APP} is already up to date."
    exit 0
  fi

  msg_info "Stopping Services"
  systemctl stop ragflow-task-executor || true
  systemctl stop ragflow-server || true
  msg_ok "Stopped Services"

  msg_info "Backing up Data"
  cp -r /opt/ragflow/conf /opt/ragflow_conf_backup
  cp -r /opt/ragflow/data /opt/ragflow_data_backup 2>/dev/null || true
  msg_ok "Backed up Data"

  msg_info "Updating ${APP}"
  $STD git fetch origin
  $STD git reset --hard origin/main
  $STD git describe --tags --abbrev=0 > /opt/ragflow/version.txt 2>/dev/null || true
  msg_ok "Updated ${APP}"

  # Fix: Replace gitee.com graspologic dependency with GitHub version
  # RAGFlow's pyproject.toml references a gitee.com fork that requires authentication
  # We replace it with the GitHub mirror which is publicly accessible
  if grep -q "gitee.com/infiniflow/graspologic" pyproject.toml 2>/dev/null; then
    msg_info "Replacing gitee.com graspologic dependency with GitHub version"
    sed -i 's|gitee.com/infiniflow/graspologic|github.com/infiniflow/graspologic|g' pyproject.toml
    msg_ok "Fixed graspologic dependency"
  fi

  # Fix: Limit Python version to avoid dependency resolution for future Python versions
  # RAGFlow's dependencies have conflicts when resolving for Python 3.14+
  if grep -q 'requires-python' pyproject.toml 2>/dev/null; then
    sed -i 's/requires-python.*/requires-python = ">=3.10,<3.13"/' pyproject.toml
  else
    sed -i '/^\[project\]/a requires-python = ">=3.10,<3.13"' pyproject.toml
  fi

  # Fix: Add uv environments configuration to limit to Linux x86_64 only
  # This avoids dependency resolution conflicts on macOS/Darwin and ARM64
  # where some packages (zhipuai, mcp) have conflicting PyJWT requirements
  if ! grep -q 'tool.uv.environments' pyproject.toml 2>/dev/null; then
    cat >> pyproject.toml << 'UVENV'

[tool.uv]
environments = ["sys_platform == 'linux' and platform_machine == 'x86_64'"]
UVENV
  fi

  msg_info "Reinstalling Python Dependencies"
  cd /opt/ragflow
  export UV_SYSTEM_PYTHON=1
  $STD /root/.local/bin/uv sync --python 3.12 --index-strategy unsafe-best-match
  $STD /root/.local/bin/uv run --index-strategy unsafe-best-match download_deps.py
  msg_ok "Reinstalled Python Dependencies"

  msg_info "Restoring Configuration"
  cp -r /opt/ragflow_conf_backup/. /opt/ragflow/conf/
  rm -rf /opt/ragflow_conf_backup /opt/ragflow_data_backup
  msg_ok "Restored Configuration"

  msg_info "Starting Services"
  systemctl start ragflow-server
  systemctl start ragflow-task-executor
  msg_ok "Started Services"

  msg_ok "Updated successfully!"
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
