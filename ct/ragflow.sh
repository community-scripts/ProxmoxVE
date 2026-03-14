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

  cd /opt/ragflow || exit
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

  # Fix: Replace gitee.com URLs with GitHub URLs
  # RAGFlow's pyproject.toml and uv.lock may reference gitee.com which requires authentication
  # We replace with GitHub mirror which is publicly accessible
  if grep -q "gitee.com/infiniflow/graspologic" pyproject.toml 2>/dev/null; then
    msg_info "Replacing gitee.com URLs in pyproject.toml with GitHub"
    sed -i 's|gitee.com/infiniflow/graspologic|github.com/infiniflow/graspologic|g' pyproject.toml
    msg_ok "Fixed graspologic URLs in pyproject.toml"
  fi
  if grep -q "gitee.com/infiniflow/graspologic" uv.lock 2>/dev/null; then
    msg_info "Replacing gitee.com URLs in uv.lock with GitHub"
    sed -i 's|gitee.com/infiniflow/graspologic|github.com/infiniflow/graspologic|g' uv.lock
    msg_ok "Fixed graspologic URLs in lock file"
  fi

  # Fix: Replace Chinese PyPI mirror with standard PyPI
  # RAGFlow uses pypi.tuna.tsinghua.edu.cn which may not have all packages
  if grep -q "pypi.tuna.tsinghua.edu.cn" pyproject.toml 2>/dev/null; then
    msg_info "Replacing Chinese PyPI mirror with standard PyPI"
    sed -i 's|pypi.tuna.tsinghua.edu.cn/simple|pypi.org/simple|g' pyproject.toml
    msg_ok "Fixed PyPI index URL in pyproject.toml"
  fi
  if grep -q "pypi.tuna.tsinghua.edu.cn" uv.lock 2>/dev/null; then
    msg_info "Replacing Chinese PyPI mirror in uv.lock with standard PyPI"
    sed -i 's|pypi.tuna.tsinghua.edu.cn/simple|pypi.org/simple|g' uv.lock
    msg_ok "Fixed PyPI index URL in lock file"
  fi

  # Fix: Ensure Python version constraint matches upstream
  # RAGFlow upstream uses requires-python = ">=3.12,<3.15"
  # infinity-sdk requires Python >=3.11,<3.14
  # The intersection is >=3.12,<3.14, but we keep upstream's constraint
  # and rely on the lock file for correct resolution
  if grep -q 'requires-python' pyproject.toml 2>/dev/null; then
    # Only update if it doesn't match upstream
    if ! grep -q 'requires-python = ">=3.12,<3.15"' pyproject.toml 2>/dev/null; then
      msg_info "Updating Python version constraint to match upstream"
      sed -i 's/requires-python\s*=.*/requires-python = ">=3.12,<3.15"/' pyproject.toml
      msg_ok "Updated Python version constraint"
    fi
  fi

  # Note: We do NOT remove zhipuai or agentrun-sdk from pyproject.toml
  # These are resolved correctly in the upstream uv.lock file
  # Removing them would require regenerating the lock file, which causes issues

  # Install Python dependencies using the upstream lock file
  # The --frozen flag tells uv to use the lock file as-is without re-resolution
  # This is the official RAGFlow installation method from their documentation
  # Reference: https://ragflow.io/docs/launch_ragflow_from_source
  msg_info "Reinstalling Python Dependencies"
  cd /opt/ragflow || exit
  export UV_SYSTEM_PYTHON=1
  $STD /root/.local/bin/uv sync --python 3.12 --frozen
  $STD /root/.local/bin/uv run download_deps.py
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
