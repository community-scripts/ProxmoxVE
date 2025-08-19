#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://technitium.com/dns/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing ASP.NET Core Runtime"
curl -fsSL "https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb" -o "packages-microsoft-prod.deb"
$STD dpkg -i packages-microsoft-prod.deb
rm -rf packages-microsoft-prod.deb
$STD apt-get update
$STD apt-get install -y aspnetcore-runtime-8.0
msg_ok "Installed ASP.NET Core Runtime"

RELEASE=$(curl -fsSL https://technitium.com/dns/ | grep -oP 'Version \K[\d.]+')
msg_info "Installing Technitium DNS"
mkdir -p /opt/technitium/dns
curl -fsSL "https://download.technitium.com/dns/DnsServerPortable.tar.gz" -o /opt/DnsServerPortable.tar.gz
$STD tar zxvf /opt/DnsServerPortable.tar.gz -C /opt/technitium/dns/
echo "${RELEASE}" > ~/.technitium
msg_ok "Installed Technitium DNS"

msg_info "Creating service"
cp /opt/technitium/dns/systemd.service /etc/systemd/system/technitium.service
systemctl enable -q --now technitium
msg_ok "Service created"

motd_ssh
customize

msg_info "Cleaning up"
rm -f /opt/DnsServerPortable.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
