#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Crazywolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/guillevc/yubal

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  libssl-dev \
  libffi-dev \
  python3-dev \
  ffmpeg \
  git
msg_ok "Installed Dependencies"

msg_info "Installing Bun"
export BUN_INSTALL=/opt/bun
curl -fsSL https://bun.sh/install | $STD bash
ln -sf /opt/bun/bin/bun /usr/local/bin/bun
ln -sf /opt/bun/bin/bunx /usr/local/bin/bunx
msg_ok "Installed Bun"

UV_VERSION="0.7.19" PYTHON_VERSION="3.12" setup_uv

msg_info "Installing Deno"
$STD sh -c "curl -fsSL https://deno.land/install.sh | DENO_INSTALL=/usr/local sh -s -- -y"
msg_ok "Installed Deno"

msg_info "Creating directories"
mkdir -p /opt/yubal \
  /opt/yubal_data \
  /opt/yubal_config
msg_ok "Created directories"

fetch_and_deploy_gh_release "yubal" "guillevc/yubal" "tarball" "latest" "/opt/yubal"

msg_info "Building Frontend"
cd /opt/yubal/web
$STD bun install --frozen-lockfile
VERSION=$(get_latest_github_release "guillevc/yubal")
VITE_VERSION=$VERSION VITE_COMMIT_SHA=$VERSION VITE_IS_RELEASE=true $STD bun run build
msg_ok "Built Frontend"

msg_info "Installing Python Dependencies"
cd /opt/yubal
export UV_CONCURRENT_DOWNLOADS=1
$STD uv sync --package yubal-api --no-dev --frozen
msg_ok "Installed Python Dependencies"

msg_info "Creating Service"
cat <<EOF >/opt/yubal.env
YUBAL_HOST=0.0.0.0
YUBAL_PORT=8000
YUBAL_DATA=/opt/yubal_data
YUBAL_CONFIG=/opt/yubal_config
YUBAL_ROOT=/opt/yubal
PYTHONUNBUFFERED=1
EOF
cat <<EOF >/etc/systemd/system/yubal.service
[Unit]
Description=Yubal
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/yubal
EnvironmentFile=/opt/yubal.env
Environment="PATH=/opt/yubal/.venv/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=/opt/yubal/.venv/bin/python -m yubal_api
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now yubal
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
