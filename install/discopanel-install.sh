#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
# Author: DragoQC
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://discopanel.app/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y build-essential
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
setup_go
fetch_and_deploy_gh_release "discopanel" "nickheyer/discopanel" "tarball" "latest" "/opt/discopanel"
setup_docker

msg_info "Setting up DiscoPanel"
cd /opt/discopanel/web/discopanel
$STD npm install
$STD npm run build
cd /opt/discopanel
$STD go build -o discopanel cmd/discopanel/main.go
msg_ok "Setup DiscoPanel"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/discopanel.service
[Unit]
Description=DiscoPanel Service
After=network.target

[Service]
WorkingDirectory=/opt/discopanel
ExecStart=/opt/discopanel/discopanel
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now discopanel
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
