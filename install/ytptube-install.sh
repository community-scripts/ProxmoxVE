#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/arabcoders/ytptube

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y libmagic1
msg_ok "Installed Dependencies"

setup_ffmpeg
setup_hwaccel
NODE_VERSION="24" NODE_MODULE="bun" setup_nodejs
PYTHON_VERSION="3.13" setup_uv
fetch_and_deploy_gh_release "deno" "denoland/deno" "prebuild" "latest" "/usr/local/bin" "deno-$(arch_resolve "x86_64" "aarch64")-unknown-linux-gnu.zip"
fetch_and_deploy_gh_release "ytptube" "arabcoders/ytptube" "tarball"

msg_info "Building YTPTube"
cd /opt/ytptube/ui
$STD bun install --frozen-lockfile --production
NODE_ENV=production $STD bun run generate
rm -rf /opt/ytptube/ui/node_modules
cd /opt/ytptube
sed -i "s/^APP_VERSION = .*/APP_VERSION = \"v$(cat ~/.ytptube)\"/" app/library/version.py
$STD uv sync --locked --no-dev
$STD uv pip install --python .venv/bin/python pip
msg_ok "Built YTPTube"

msg_info "Configuring YTPTube"
mkdir -p /opt/ytptube_data/{config,downloads,tmp}
cat <<EOF >/opt/ytptube_data/config/.env
YTP_PORT=8081
YTP_CONFIG_PATH=/opt/ytptube_data/config
YTP_DOWNLOAD_PATH=/opt/ytptube_data/downloads
YTP_TEMP_PATH=/opt/ytptube_data/tmp
EOF
msg_ok "Configured YTPTube"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/ytptube.service
[Unit]
Description=YTPTube
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/ytptube
EnvironmentFile=/opt/ytptube_data/config/.env
Environment=PATH=/opt/ytptube/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
ExecStartPre=-/opt/ytptube/.venv/bin/python /opt/ytptube/app/upgrader.py
ExecStart=/opt/ytptube/.venv/bin/python /opt/ytptube/app/main.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ytptube
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
