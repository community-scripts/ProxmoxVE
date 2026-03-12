#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mcmonkeyprojects/SwarmUI

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
setup_deb822_repo \
  "microsoft" \
  "https://packages.microsoft.com/keys/microsoft-2025.asc" \
  "https://packages.microsoft.com/debian/13/prod/" \
  "trixie" \
  "main"
$STD apt install -y \
  git \
  libicu-dev \
  libssl-dev \
  dotnet-sdk-8.0 \
  aspnetcore-runtime-8.0 \
  python3-full \
  python3-pip \
  python3-venv
msg_ok "Installed Dependencies"

msg_info "Cloning SwarmUI"
mkdir -p /opt/swarmui
$STD git clone https://github.com/mcmonkeyprojects/SwarmUI.git /opt/swarmui
cd /opt/swarmui || exit
msg_ok "Cloned SwarmUI"

msg_info "Building SwarmUI"
$STD dotnet build src/SwarmUI.csproj --configuration Release -o ./bin
msg_ok "Built SwarmUI"

msg_info "Creating Directories"
mkdir -p /opt/swarmui/Models
mkdir -p /opt/swarmui/Output
msg_ok "Created Directories"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/swarmui.service
[Unit]
Description=SwarmUI - Stable Diffusion WebUI
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/swarmui
ExecStart=/usr/bin/dotnet /opt/swarmui/bin/SwarmUI.dll --launch_mode none --host 0.0.0.0
Environment=ASPNETCORE_URLS=http://0.0.0.0:7801
Environment=DOTNET_CONTENTROOT=/opt/swarmui
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now swarmui
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
