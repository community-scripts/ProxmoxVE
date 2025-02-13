#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Kristian Skov
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
$STD apt install -y \
	curl \
  mc \
  sudo \
	gpg \
	coreutils
msg_ok "Installed Dependencies"

msg_info "Setup SQL Server 2022"
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list | sudo tee /etc/apt/sources.list.d/mssql-server-2022.list
#$STD curl https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc
#$STD curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list | tee /etc/apt/sources.list.d/mssql-server-2022.list
$STD apt-get clean *
$STD apt-get update -y
apt-get install -y mssql-server
msg_ok "Setup Server 2022"

msg_info "Installing SQL Server Tools"
export DEBIAN_FRONTEND=noninteractive
export ACCEPT_EULA=Y
curl https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | tee /etc/apt/sources.list.d/mssql-release.list
$STD apt-get update
$STD apt-get install -y -qq \
  mssql-tools18 \
  unixodbc-dev
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bash_profile
source ~/.bash_profile
msg_ok "Installed SQL Server Tools"

read -r -p "Do you want to run the SQL server setup now? (Later is also possible) <y/N>" prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  /opt/mssql/bin/mssql-conf setup
else
  msg_ok "Skipping SQL Server setup. You can run it later with '/opt/mssql/bin/mssql-conf setup'."
fi

msg_info "Start Service"
systemctl enable -q --now mssql-server 
msg_ok "Service started"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
