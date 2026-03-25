#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: aendel
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/nightscout/cgm-remote-monitor

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
  openssl
msg_ok "Installed Dependencies"

MONGO_VERSION="8.0" setup_mongodb
NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "nightscout" "nightscout/cgm-remote-monitor" "tarball"

msg_info "Installing Nightscout"
$STD npm install --prefix /opt/nightscout
msg_ok "Installed Nightscout"

msg_info "Creating Service"
useradd -s /bin/bash -m nightscout
chown -R nightscout:nightscout /opt/nightscout
API_SECRET=$(openssl rand -hex 16)
cat <<EOF >/opt/nightscout/my.env
MONGO_CONNECTION=mongodb://127.0.0.1:27017/nightscout
BASE_URL=http://localhost:1337
API_SECRET=${API_SECRET}
DISPLAY_UNITS=mg/dl
ENABLE=careportal boluscalc food bwp cage sage iage iob cob basal ar2 rawbg pushover bgi pump openaps pvb linear custom
INSECURE_USE_HTTP=true
EOF
chown nightscout:nightscout /opt/nightscout/my.env
cat <<EOF >/etc/systemd/system/nightscout.service
[Unit]
Description=Nightscout CGM Service
After=network.target mongodb.service

[Service]
Type=simple
User=nightscout
WorkingDirectory=/opt/nightscout
EnvironmentFile=/opt/nightscout/my.env
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now nightscout
msg_ok "Created Service"

{
  echo "Nightscout Credentials"
  echo "API_SECRET: ${API_SECRET}"
} >> ~/nightscout.creds

motd_ssh
customize
cleanup_lxc
