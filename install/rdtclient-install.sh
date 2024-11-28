#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
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
$STD apt-get install -y \
  mc \
  curl \
  sudo 
msg_ok "Installed Dependencies"

msg_info "Installing ASP.NET Core Runtime"
wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb
$STD dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
$STD apt-get update
$STD apt-get install -y dotnet-sdk-9.0
msg_ok "Installed ASP.NET Core Runtime"

msg_info "Installing rdtclient"
wget -q https://github.com/rogerfar/rdt-client/releases/latest/download/RealDebridClient.zip
unzip -qq RealDebridClient.zip -d /opt/rdtc
rm RealDebridClient.zip
cd /opt/rdtc
mkdir -p data/{db,downloads}
sed -i 's#/data/db/#/opt/rdtc&#g' /opt/rdtc/appsettings.json
msg_ok "Installed rdtclient"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/rdtc.service
[Unit]
Description=RdtClient Service

[Service]
WorkingDirectory=/opt/rdtc
ExecStart=/usr/bin/dotnet RdtClient.Web.dll
SyslogIdentifier=RdtClient
User=root

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable -q --now rdtc
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
