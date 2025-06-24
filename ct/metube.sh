#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alexta69/metube

APP="MeTube"
var_tags="${var_tags:-media;youtube}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/metube ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Stopping ${APP} Service"
  systemctl stop metube
  msg_ok "Stopped ${APP} Service"

  msg_info "Backing up Old Installation"
  if [[ -d /opt/metube_bak ]]; then
    rm -rf /opt/metube_bak
  fi
  mv /opt/metube /opt/metube_bak
  msg_ok "Backup created"

  msg_info "Cloning Latest ${APP} Release"
  $STD git clone https://github.com/alexta69/metube /opt/metube
  msg_ok "Cloned ${APP}"

  msg_info "Building Frontend"
  cd /opt/metube/ui
  $STD npm install
  $STD node_modules/.bin/ng build
  msg_ok "Built Frontend"

  PYTHON_VERSION="3.13" setup_uv

  msg_info "Setting up Python Environment (uv)"
  $STD uv venv /opt/metube/.venv
  $STD /opt/metube/.venv/bin/python -m ensurepip --upgrade
  $STD /opt/metube/.venv/bin/python -m pip install --upgrade pip
  $STD /opt/metube/.venv/bin/python -m pip install pipenv
  msg_ok "Python Environment Ready"

  msg_info "Installing Backend Requirements"
  cd /opt/metube
  $STD /opt/metube/.venv/bin/pipenv install
  msg_ok "Installed Backend"

  msg_info "Restoring Environment File"
  if [[ -f /opt/metube_bak/.env ]]; then
    cp /opt/metube_bak/.env /opt/metube/.env
  fi
  msg_ok "Restored .env"

  if [[ ! -d /opt/metube/.venv ]]; then
    msg_info "Migrating to uv-based environment"
    PYTHON_VERSION="3.13" setup_uv
    $STD uv venv /opt/metube/.venv
    $STD /opt/metube/.venv/bin/python -m ensurepip --upgrade
    $STD /opt/metube/.venv/bin/python -m pip install --upgrade pip
    $STD /opt/metube/.venv/bin/python -m pip install pipenv
    $STD /opt/metube/.venv/bin/pipenv install
    $STD /opt/metube/.venv/bin/pipenv update yt-dlp

    msg_info "Patching systemd Service"
    cat <<EOF >/etc/systemd/system/metube.service
[Unit]
Description=Metube - YouTube Downloader
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/metube
EnvironmentFile=/opt/metube/.env
ExecStart=/opt/metube/.venv/bin/pipenv run python3 app/main.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
    msg_ok "Patched systemd Service"
  fi
  $STD systemctl daemon-reload
  msg_ok "Service Updated"

  msg_info "Cleaning up"
  rm -rf /opt/metube_bak
  $STD apt-get -y autoremove
  $STD apt-get -y autoclean
  msg_ok "Cleaned Up"

  msg_info "Starting ${APP} Service"
  systemctl enable -q --now metube
  sleep 1
  msg_ok "Started ${APP} Service"

  msg_ok "Updated Successfully!"
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8081${CL}"
