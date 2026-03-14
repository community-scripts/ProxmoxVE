#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: BillyOutlast
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mudler/LocalAI

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "local-ai" "mudler/LocalAI" "singlefile" "latest" "/usr/local/bin" "local-ai-v*-linux-*"

msg_info "Setting Up Service"
mkdir -p /opt/localai/models
cat <<EOF >/etc/systemd/system/localai.service
[Unit]
Description=LocalAI - OpenAI-compatible local inference server
After=network.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/local-ai
Restart=on-failure
RestartSec=5
Environment=LOCALAI_MODELS_PATH=/opt/localai/models

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now localai
msg_ok "Set Up Service"

motd_ssh
customize
cleanup_lxc
