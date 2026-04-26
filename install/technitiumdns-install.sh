#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
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

msg_info "Installing Dependencies"
setup_deb822_repo \
  "microsoft" \
  "https://packages.microsoft.com/keys/microsoft-2025.asc" \
  "https://packages.microsoft.com/debian/13/prod/" \
  "trixie" \
  "main"
$STD apt install -y aspnetcore-runtime-10.0
msg_ok "Installed Dependencies"

RELEASE=$(curl -fsSL https://technitium.com/dns/ | grep -oP 'Version \K[\d.]+')
fetch_and_deploy_from_url "https://download.technitium.com/dns/DnsServerPortable.tar.gz" /opt/technitium/dns
echo "${RELEASE}" >~/.technitium

msg_info "Creating service"
mkdir -p /etc/dns /var/log/technitium/dns
sed -i '/^User=/d;/^Group=/d' /opt/technitium/dns/systemd.service
cp /opt/technitium/dns/systemd.service /etc/systemd/system/technitium.service
systemctl enable -q --now technitium
msg_ok "Service created"

motd_ssh
customize
cleanup_lxc
