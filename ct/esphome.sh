#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://esphome.io/

APP="ESPHome"
var_tags="${var_tags:-automation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/esphomeDashboard.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi

  msg_info "Stopping ${APP}"
  systemctl stop esphomeDashboard
  msg_ok "Stopped ${APP}"

  VENV_PATH="/opt/esphome/.venv"
  ESPHOME_BIN="${VENV_PATH}/bin/esphome"
  export PYTHON_VERSION="3.12"

  if [[ ! -d "$VENV_PATH" || ! -x "$ESPHOME_BIN" ]]; then
    PYTHON_VERSION="3.12" setup_uv
    msg_info "Migrating to uv/venv"
    rm -rf "$VENV_PATH"
    mkdir -p /opt/esphome
    cd /opt/esphome
    $STD uv venv "$VENV_PATH"
    $STD "$VENV_PATH/bin/python" -m ensurepip --upgrade
    $STD "$VENV_PATH/bin/python" -m pip install --upgrade pip
    $STD "$VENV_PATH/bin/python" -m pip install esphome tornado esptool
    msg_ok "Migrated to uv/venv"
  else
    msg_info "Updating ESPHome"
    PYTHON_VERSION="3.12" setup_uv
    $STD "$VENV_PATH/bin/python" -m pip install --upgrade esphome tornado esptool
    msg_ok "Updated ESPHome"
  fi
  SERVICE_FILE="/etc/systemd/system/esphomeDashboard.service"
  if ! grep -q "${VENV_PATH}/bin/esphome" "$SERVICE_FILE"; then
    msg_info "Updating systemd service"
    cat <<EOF >"$SERVICE_FILE"
[Unit]
Description=ESPHome Dashboard
After=network.target

[Service]
ExecStart=${VENV_PATH}/bin/esphome dashboard /root/config/
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
    $STD systemctl daemon-reload
    msg_ok "Updated systemd service"
  fi

  msg_info "Linking esphome to /usr/local/bin"
  rm -f /usr/local/bin/esphome
  ln -s /opt/esphome/.venv/bin/esphome /usr/local/bin/esphome
  msg_ok "Linked esphome binary"

  msg_info "Starting ${APP}"
  systemctl start esphomeDashboard
  msg_ok "Started ${APP}"
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6052${CL}"
