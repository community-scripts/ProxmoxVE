#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: remz1337
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y apt-transport-https
$STD apt-get install -y gpg
$STD apt-get install -y xvfb
msg_ok "Installed Dependencies"

msg_info "Installing Chrome"
wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
$STD apt update
$STD apt install -y google-chrome-stable
msg_ok "Installed Chrome"

msg_info "Installing FlareSolverr"
RELEASE=$(wget -q https://github.com/FlareSolverr/FlareSolverr/releases/latest -O - | grep "title>Release" | cut -d " " -f 4)
$STD wget -q https://github.com/FlareSolverr/FlareSolverr/releases/download/$RELEASE/flaresolverr_linux_x64.tar.gz
$STD tar -xzf flaresolverr_linux_x64.tar.gz -C /opt
$STD rm flaresolverr_linux_x64.tar.gz
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed FlareSolverr"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/flaresolverr.service
[Unit]
Description=FlareSolverr
After=network.target
[Service]
SyslogIdentifier=flaresolverr
Restart=always
RestartSec=5
Type=simple
Environment="LOG_LEVEL=info"
Environment="CAPTCHA_SOLVER=none"
WorkingDirectory=/opt/flaresolverr
ExecStart=/opt/flaresolverr/flaresolverr
TimeoutStopSec=30
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now flaresolverr.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
