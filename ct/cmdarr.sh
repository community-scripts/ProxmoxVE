#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: cjarvis
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DeviantEng/Cmdarr

APP="Cmdarr"
var_tags="${var_tags:-arr;music;automation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -d /opt/cmdarr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  CURRENT=$(cat /opt/cmdarr_version.txt 2>/dev/null || echo "none")
  LATEST=$(curl -sL https://api.github.com/repos/DeviantEng/Cmdarr/tags | python3 -c "import json,sys;d=json.load(sys.stdin);print(d[0]['name'] if d else '')")

  if [[ -z "${LATEST}" ]]; then
    msg_error "Failed to fetch latest version (GitHub API rate limit?)"
    exit
  fi

  if [[ "${CURRENT}" == "${LATEST}" ]]; then
    msg_ok "${APP} is already up to date (${CURRENT})"
    exit
  fi

  msg_info "Stopping ${APP}"
  systemctl stop cmdarr
  msg_ok "Stopped ${APP}"

  msg_info "Creating Backup"
  cp -r /opt/cmdarr/data /opt/cmdarr-data-backup
  msg_ok "Backup Created"

  msg_info "Updating ${APP} (${CURRENT} → ${LATEST})"
  export PATH="/root/.local/bin:$PATH"
  export UV_PYTHON_INSTALL_DIR="/opt/uv-python"
  rm -rf /opt/cmdarr/.venv /opt/cmdarr/frontend /opt/cmdarr/app /opt/cmdarr/commands /opt/cmdarr/clients /opt/cmdarr/services /opt/cmdarr/utils
  $STD curl -fsSL "https://github.com/DeviantEng/Cmdarr/archive/refs/tags/${LATEST}.tar.gz" -o /tmp/cmdarr.tar.gz
  tar -xzf /tmp/cmdarr.tar.gz --strip-components=1 -C /opt/cmdarr
  rm -f /tmp/cmdarr.tar.gz
  cd /opt/cmdarr || exit

  REQUIRED_PY=$(cat .python-version 2>/dev/null || echo "3.14")
  if ! uv python find "${REQUIRED_PY}" &>/dev/null; then
    msg_info "Installing Python ${REQUIRED_PY}"
    $STD uv python install "${REQUIRED_PY}"
    chmod -R 755 /opt/uv-python
    # Remove old Python versions
    find /opt/uv-python -maxdepth 1 -type d -name "cpython-*" ! -name "*${REQUIRED_PY}*" -exec rm -rf {} +
  fi

  REQUIRED_NODE=$(cat .nvmrc 2>/dev/null || echo "24")
  CURRENT_NODE=$(node --version 2>/dev/null | cut -d. -f1 | tr -d 'v')
  if [[ "${CURRENT_NODE}" != "${REQUIRED_NODE}" ]]; then
    msg_info "Node.js version changed (${CURRENT_NODE} → ${REQUIRED_NODE}), updating"
    $STD curl -fsSL "https://deb.nodesource.com/setup_${REQUIRED_NODE}.x" | $STD bash -
    $STD apt-get install -y nodejs
  fi

  $STD uv venv --python "${REQUIRED_PY}" .venv
  $STD uv pip install --python .venv/bin/python -r requirements.txt
  cd frontend && $STD npm ci && $STD npm run build && cd ..
  mv /opt/cmdarr-data-backup /opt/cmdarr/data
  echo "${LATEST}" >/opt/cmdarr_version.txt
  chown -R cmdarr:cmdarr /opt/cmdarr
  msg_ok "Updated ${APP}"

  msg_info "Starting ${APP}"
  systemctl start cmdarr
  msg_ok "Started ${APP}"

  msg_ok "Updated successfully to ${LATEST}!"
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
