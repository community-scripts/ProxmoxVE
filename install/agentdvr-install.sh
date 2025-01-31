#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
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
$STD apt-get install -y unzip
$STD apt-get install -y apt-transport-https
$STD apt-get install -y alsa-utils
$STD apt-get install -y libxext-dev
$STD apt-get install -y fontconfig
$STD apt-get install -y libva-drm2
msg_ok "Installed Dependencies"

msg_info "Installing AgentDVR"
mkdir -p /opt/agentdvr/agent
RELEASE=$(curl -s "https://www.ispyconnect.com/api/Agent/DownloadLocation4?platform=Linux64&fromVersion=0" | grep -o 'https://.*\.zip')
cd /opt/agentdvr/agent
wget -q $RELEASE
$STD unzip Agent_Linux64*.zip
rm -rf Agent_Linux64*.zip
chmod +x ./Agent
msg_ok "Installed AgentDVR"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/AgentDVR.service
[Unit]
Description=AgentDVR

[Service]
WorkingDirectory=/opt/agentdvr/agent
ExecStart=/opt/agentdvr/agent/./Agent
Environment="MALLOC_TRIM_THRESHOLD_=100000"
SyslogIdentifier=AgentDVR
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now AgentDVR.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
