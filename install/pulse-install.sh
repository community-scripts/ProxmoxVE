#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: rcourtman
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rcourtman/Pulse

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  diffutils \
  policykit-1
msg_ok "Installed Dependencies"

msg_info "Creating dedicated user pulse..."
if useradd -r -m -d /opt/pulse-home -s /bin/bash pulse; then
  msg_ok "User created."
else
  msg_error "User creation failed."
  exit 1
fi

NODE_VERSION="20" setup_nodejs

msg_info "Setup Pulse"
RELEASE=$(curl -fsSL https://api.github.com/repos/rcourtman/Pulse/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
temp_file=$(mktemp)
mkdir -p /opt/pulse
curl -fsSL "https://github.com/rcourtman/Pulse/releases/download/v${RELEASE}/pulse-v${RELEASE}.tar.gz" -o "$temp_file"
tar zxf "$temp_file" --strip-components=1 -C /opt/pulse
touch /opt/pulse/.env
chown pulse:pulse /opt/pulse/.env
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Pulse"

msg_info "Setting permissions for /opt/pulse..."
chown -R pulse:pulse "/opt/pulse"
find "/opt/pulse" -type d -exec chmod 755 {} \;
find "/opt/pulse" -type f -exec chmod 644 {} \;
msg_ok "Set permissions."

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pulse.service
[Unit]
Description=Pulse Monitoring Application
After=network.target

[Service]
Type=simple
User=pulse
Group=pulse
WorkingDirectory=/opt/pulse
EnvironmentFile=/opt/pulse/.env
ExecStart=/usr/bin/npm run start
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pulse
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
