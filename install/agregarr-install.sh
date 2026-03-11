#!/usr/bin/env bash

# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/agregarr/agregarr

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
  python3 \
  sqlite3
msg_ok "Installed Dependencies"

NODE_VERSION="20" NODE_MODULE="yarn" setup_nodejs

fetch_and_deploy_gh_release "agregarr" "agregarr/agregarr" "tarball"

msg_info "Building Application"
cd /opt/agregarr
$STD yarn install
$STD yarn build
msg_ok "Built Application"

msg_info "Creating Config Directory"
mkdir -p /opt/agregarr/config
msg_ok "Created Config Directory"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/agregarr.service
[Unit]
Description=Agregarr Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/agregarr
Environment=NODE_ENV=production
ExecStart=/usr/bin/yarn start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now agregarr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
