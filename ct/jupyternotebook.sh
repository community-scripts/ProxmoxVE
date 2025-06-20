#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Dave-code-creater (Tan Dat, Ta)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://jupyter.org/

APP="JupyterNotebook"
var_tags="${var_tags:-ai;dev-tools}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  INSTALL_DIR="/opt/jupyter"
  VENV_PYTHON="${INSTALL_DIR}/.venv/bin/python"
  VENV_JUPYTER="${INSTALL_DIR}/.venv/bin/jupyter"
  SERVICE_FILE="/etc/systemd/system/jupyternotebook.service"

  if [[ ! -x "$VENV_JUPYTER" ]]; then
    msg_info "Migrating to uv venv"
    PYTHON_VERSION="3.12" setup_uv
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    $STD uv venv .venv
    $STD "$VENV_PYTHON" -m ensurepip --upgrade
    $STD "$VENV_PYTHON" -m pip install --upgrade pip
    $STD "$VENV_PYTHON" -m pip install jupyter
    msg_ok "Migrated to uv and installed Jupyter"
  else
    msg_info "Updating Jupyter"
    $STD "$VENV_PYTHON" -m pip install --upgrade pip
    $STD "$VENV_PYTHON" -m pip install --upgrade jupyter
    msg_ok "Jupyter updated"
  fi

  if [[ -f "$SERVICE_FILE" && "$(grep ExecStart "$SERVICE_FILE")" != *".venv/bin/jupyter"* ]]; then
    msg_info "Updating systemd service to use .venv"
    cat <<EOF >"$SERVICE_FILE"
[Unit]
Description=Jupyter Notebook Server
After=network.target
[Service]
Type=simple
WorkingDirectory=${INSTALL_DIR}
ExecStart=${VENV_JUPYTER} notebook --ip=0.0.0.0 --port=8888 --allow-root
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reexec
    systemctl restart jupyternotebook
    msg_ok "Service updated and restarted"
  fi

  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8888${CL}"
