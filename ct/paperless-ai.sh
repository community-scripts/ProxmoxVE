#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
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
var_arm64="${var_arm64:-yes}"
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

  if check_for_gh_release "paperless-ai" "clusterzx/paperless-ai"; then
    msg_info "Stopping Service"
    systemctl stop paperless-ai
    if [[ -f /etc/systemd/system/paperless-rag.service ]]; then
      systemctl stop paperless-rag
    fi
    msg_ok "Stopped Service"

    NODE_VERSION="22" setup_nodejs
    CLEAN_INSTALL=1 CLEAN_INSTALL_KEEP="data" fetch_and_deploy_gh_release "paperless-ai" "clusterzx/paperless-ai" "tarball"

    msg_info "Updating Paperless-AI"
    cd /opt/paperless-ai
    export ONNXRUNTIME_NODE_INSTALL=skip PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
    $STD npm ci --ignore-scripts --no-audit --no-fund
    $STD npm run build
    $STD npm prune --omit=dev --ignore-scripts --no-audit --no-fund
    msg_ok "Updated Paperless-AI"

    if ! grep -q "dist/server/index.js" /etc/systemd/system/paperless-ai.service; then
      msg_info "Migrating services to Paperless-AI 4"
      if [[ -f /etc/systemd/system/paperless-rag.service ]]; then
        systemctl disable -q paperless-rag
        rm -f /etc/systemd/system/paperless-rag.service
      fi
      cat <<EOF >/etc/systemd/system/paperless-ai.service
[Unit]
Description=PaperlessAI Service
After=network.target

[Service]
WorkingDirectory=/opt/paperless-ai
Environment="NODE_ENV=production"
Environment="PAPERLESS_AI_PORT=3000"
Environment="PAPERLESS_AI_DATA_DIR=/opt/paperless-ai/data"
Environment="HF_HUB_DISABLE_TELEMETRY=1"
ExecStart=/usr/bin/node dist/server/index.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF
      systemctl daemon-reload
      msg_ok "Migrated services to Paperless-AI 4"
      msg_warn "Settings and history from 3.x are migrated on first start. If this instance was reachable from the internet, read 'Upgrading from 3.x' in the upstream README first."
    fi

    msg_info "Starting Service"
    systemctl start paperless-ai
    msg_ok "Started Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
