#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: BillyOutlast
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mudler/LocalAGI

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
APP="LocalAGI"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="24" setup_nodejs
setup_go

msg_info "Installing Bun"
export BUN_INSTALL="/root/.bun"
curl -fsSL https://bun.sh/install | $STD bash
ln -sf /root/.bun/bin/bun /usr/local/bin/bun
ln -sf /root/.bun/bin/bunx /usr/local/bin/bunx
msg_ok "Installed Bun"

fetch_and_deploy_gh_release "localagi" "mudler/LocalAGI" "tarball" "latest" "/opt/localagi"

msg_info "Configuring LocalAGI"
mkdir -p /opt/localagi/pool
cat <<'EOF' >/opt/localagi/.env
LOCALAGI_MODEL=gemma-3-4b-it-qat
LOCALAGI_MULTIMODAL_MODEL=moondream2-20250414
LOCALAGI_IMAGE_MODEL=sd-1.5-ggml
LOCALAGI_LLM_API_URL=http://127.0.0.1:11434/v1
LOCALAGI_STATE_DIR=/opt/localagi/pool
EOF
msg_ok "Configured LocalAGI"

msg_info "Setting up LocalAGI"
cd /opt/localagi/webui/react-ui
$STD bun install
$STD bun run build
cd /opt/localagi
$STD go build -o /usr/local/bin/localagi
msg_ok "Set up LocalAGI"

msg_info "Creating LocalAGI systemd service"
cat <<EOF >/etc/systemd/system/localagi.service
[Unit]
Description=LocalAGI
After=network.target

[Service]
User=root
Type=simple
EnvironmentFile=/opt/localagi/.env

WorkingDirectory=/opt/localagi
ExecStart=/usr/local/bin/localagi
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now localagi
msg_ok "Created LocalAGI systemd service"

motd_ssh
customize
cleanup_lxc
