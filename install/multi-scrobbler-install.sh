#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: tremor021
# License: MIT
# Source: https://foxxmd.github.io/multi-scrobbler/

# Import Functions und Setup
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
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
  wget \
  [PACKAGE_2] \
  [PACKAGE_3]
msg_ok "Installed Dependencies"

msg_info "Setup ${APPLICATION}"
RELEASE=$(curl -s https://api.github.com/repos/FoxxMD/multi-scrobbler/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q https://github.com/FoxxMD/multi-scrobbler/archive/refs/tags/${RELEASE}.tar.gz
tar -xzf ${RELEASE}.tar.gz
mv ${APPLICATION}-${RELEASE}/ /opt/${APPLICATION}
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Setup ${APPLICATION}"

# Creating Service (if needed)
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/${APPLICATION}.service
[Unit]
Description=multi-scrobbler
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/multi-scrobbler
ExecStart=node src/index.js
Restart=no

[Install]
WantedBy=default.target
EOF
systemctl enable -q --now ${APPLICATION}.service
msg_ok "Created Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
rm -f ${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize