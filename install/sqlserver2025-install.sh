#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.microsoft.com/en-us/sql-server/sql-server-2025

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y coreutils
msg_ok "Installed Dependencies"

msg_info "Setting up SQL Server 2025 Repository"
setup_deb822_repo \
  "mssql-server-2025" \
  "https://packages.microsoft.com/keys/microsoft.asc" \
  "https://packages.microsoft.com/ubuntu/24.04/mssql-server-2025" \
  "noble" \
  "main"
msg_ok "Repository configured"

msg_info "Installing SQL Server 2025"
$STD apt install -y mssql-server
msg_ok "Installed SQL Server 2025"

msg_info "Installing SQL Server Tools"
export DEBIAN_FRONTEND=noninteractive
export ACCEPT_EULA=Y
setup_deb822_repo \
  "mssql-release" \
  "https://packages.microsoft.com/keys/microsoft.asc" \
  "https://packages.microsoft.com/ubuntu/24.04/prod" \
  "noble" \
  "main"
$STD apt-get install -y \
  mssql-tools18 \
  unixodbc-dev
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >>~/.bash_profile
source ~/.bash_profile
msg_ok "Installed SQL Server Tools"

read -r -p "${TAB3}Do you want to run the SQL Server setup now? (Later is also possible) <y/N>" prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  /opt/mssql/bin/mssql-conf setup
else
  msg_ok "Skipping SQL Server setup. You can run it later with '/opt/mssql/bin/mssql-conf setup'."
fi

msg_info "Starting SQL Server Service"
systemctl enable -q --now mssql-server
msg_ok "Service started"

msg_info "Cleaning up"
rm -f /etc/profile.d/debuginfod.sh /etc/profile.d/debuginfod.csh
msg_ok "Cleaned up"

motd_ssh
customize
cleanup_lxc
