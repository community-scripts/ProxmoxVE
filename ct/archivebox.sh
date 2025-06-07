#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/python_to_uv/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://archivebox.io/

APP="ArchiveBox"
var_tags="${var_tags:-archive;bookmark}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
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
  if [[ ! -d /opt/archivebox ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Stopping ${APP}"
  systemctl stop archivebox
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP}"
  cd /opt/archivebox
  $STD uv venv --python "$UV_PYTHON_VERSION" .venv

  if [[ -f /opt/archivebox/uv.lock ]]; then
    cp /opt/archivebox/uv.lock /opt/archivebox/data/ || true
  fi

  cd /opt/archivebox/data
  $STD ../.venv/bin/uv sync

  msg_info "Running ArchiveBox Setup"
  sudo -u archivebox ../.venv/bin/playwright install-deps chromium
  sudo -u archivebox ../.venv/bin/playwright install chromium
  sudo -u archivebox ../.venv/bin/archivebox init
  msg_ok "ArchiveBox Updated"

  if grep -q "ExecStart=/usr/local/bin/archivebox" /etc/systemd/system/archivebox.service; then
    sed -i "s|ExecStart=/usr/local/bin/archivebox|ExecStart=/opt/archivebox/.venv/bin/archivebox|" /etc/systemd/system/archivebox.service
    systemctl daemon-reload
  fi

  msg_info "Starting ${APP}"
  systemctl start archivebox
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000/admin/login${CL}"
