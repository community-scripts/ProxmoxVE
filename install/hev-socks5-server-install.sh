#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: miviro
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/heiher/hev-socks5-server

# Import Functions und Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Installing Dependencies with the 3 core dependencies (curl;sudo;mc)
msg_info "Installing Dependencies"
$STD apt-get install -y \
    curl \
    sudo \
    mc \
    git \
    make \
    gcc
msg_ok "Installed Dependencies"

# Temp

# Setup App (build from source)
msg_info "Setup ${APPLICATION}"
RELEASE=$(curl -s https://api.github.com/repos/heiher/hev-socks5-server/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
git clone --recursive https://github.com/heiher/hev-socks5-server
cd hev-socks5-server || exit
make
mv bin/${APPLICATION} /opt/${APPLICATION}
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
# do not overwrite existing config
if [ ! -d "/etc/${APPLICATION}" ]; then
    mv conf/ /etc/${APPLICATION}/
fi
msg_ok "Setup ${APPLICATION}"

# Creating Service (if needed)
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/${APPLICATION}.service
[Unit]
Description=${APPLICATION} Service
After=network.target

[Service]
ExecStart=/opt/${APPLICATION} /etc/${APPLICATION}/main.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ${APPLICATION}.service
msg_ok "Created Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
rm -rf "${APPLICATION}"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
