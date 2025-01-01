#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: Scorpoon
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/revenz/Fenrus



source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y curl
$STD apt-get install -y git
msg_ok "Installed Dependencies"

msg_info "Installing ASP.NET Core 7 SDK"
var_os=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
var_version=$(grep "^VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
if [ "${var_os}" = "debian" ]; then
  wget -q "https://packages.microsoft.com/config/debian/$var_version/packages-microsoft-prod.deb"
  $STD dpkg -i packages-microsoft-prod.deb
  rm packages-microsoft-prod.deb
fi
$STD apt-get update
$STD apt-get install -y dotnet-sdk-7.0
msg_ok "Installed ASP.NET Core 7 SDK"

msg_info "Installing ${APPLICATION}"
git clone -q https://github.com/revenz/Fenrus.git /opt/${APPLICATION}
cd /opt/${APPLICATION}
$STD dotnet publish -c Release -o "/opt/${APPLICATION}/" Fenrus.csproj
msg_ok "Installed ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/"${APPLICATION}".service
[Unit]
Description=${APPLICATION}

[Service]
WorkingDirectory=/opt/${APPLICATION}
ExecStart=/usr/bin/dotnet Fenrus.dll --urls=http://*:5000
SyslogIdentifier=${APPLICATION}
User=root

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable -q --now ${APPLICATION}
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
