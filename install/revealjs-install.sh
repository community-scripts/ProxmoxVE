#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hakimel/reveal.js

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "revealjs" "hakimel/reveal.js" "tarball"

msg_info "Configuring ${APPLICATION}"
cd /opt/revealjs
$STD npm install
sed -i '25s/localhost/0.0.0.0/g' /opt/revealjs/gulpfile.js
msg_ok "Setup ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/revealjs.service
[Unit]
Description=Reveal.js Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/revealjs
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now revealjs
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
