#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/clusterzx/paperless-ai

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "paperless-ai" "clusterzx/paperless-ai" "tarball"

msg_info "Setup Paperless-AI"
cd /opt/paperless-ai
export ONNXRUNTIME_NODE_INSTALL=skip PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
$STD npm ci --ignore-scripts --no-audit --no-fund
$STD npm run build
$STD npm prune --omit=dev --ignore-scripts --no-audit --no-fund
mkdir -p /opt/paperless-ai/data
msg_ok "Setup Paperless-AI"

msg_info "Creating Service"
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
systemctl enable -q --now paperless-ai
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
