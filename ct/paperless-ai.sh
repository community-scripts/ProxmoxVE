#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/clusterzx/paperless-ai

APP="Paperless-AI"
var_tags="${var_tags:-ai;document}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
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
  if [[ ! -d /opt/paperless-ai ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if ! dpkg -s python3-pip >/dev/null 2>&1; then
    $STD apt install -y python3-pip
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/clusterzx/paperless-ai/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "Stopping Service"
    systemctl stop paperless-ai
    msg_info "Stopped Service"

    msg_info "Updating $APP to v${RELEASE}"
    cd /opt
    mv /opt/paperless-ai /opt/paperless-ai_bak
    curl -fsSL "https://github.com/clusterzx/paperless-ai/archive/refs/tags/v${RELEASE}.zip" -o $(basename "https://github.com/clusterzx/paperless-ai/archive/refs/tags/v${RELEASE}.zip")
    $STD unzip v${RELEASE}.zip
    mv paperless-ai-${RELEASE} /opt/paperless-ai
    mkdir -p /opt/paperless-ai/data
    cp -a /opt/paperless-ai_bak/data/. /opt/paperless-ai/data/
    cd /opt/paperless-ai
    if [[ ! -f /etc/systemd/system/paperless-rag.service ]]; then
      cat <<EOF >/etc/systemd/system/paperless-rag.service
[Unit]
Description=PaperlessAI-RAG Service
After=network.target

[Service]
WorkingDirectory=/opt/paperless-ai
ExecStart=/usr/bin/python3 main.py --host 0.0.0.0 --port 8000 --initialize
Restart=always

[Install]
WantedBy=multi-user.target
EOF
      echo "RAG_SERVICE_URL=http://localhost:8000" >>/opt/paperless-ai/data/.env
      echo "RAG_SERVICE_ENABLED=true" >>/opt/paperless-ai/data/.env
    fi
    $STD pip install --no-cache-dir -r requirements.txt
    mkdir -p data/chromadb
    $STD npm install
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start paperless-ai
    msg_ok "Started Service"

    msg_info "Cleaning Up"
    rm -rf /opt/v${RELEASE}.zip
    rm -rf /opt/paperless-ai_bak
    msg_ok "Cleanup Completed"
    msg_ok "Updated successfully!"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}
start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
