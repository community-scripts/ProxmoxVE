#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    curl \
    mc \
    sudo 
msg_ok "Installed Dependencies"


msg_info "Installing InspIRCd"
RELEASE=$(curl -s https://api.github.com/repos/inspircd/inspircd/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
cd /opt
wget -q https://github.com/inspircd/inspircd/releases/download/v${RELEASE}/inspircd_${RELEASE}.deb12u1_amd64.deb
$STD apt-get install "./inspircd_${RELEASE}.deb12u1_amd64.deb" -y &>/dev/null
cat <<EOF >/etc/inspircd/inspircd.conf
<define name="networkDomain" value="helper-scripts.com">
<define name="networkName" value="Proxmox VE Helper-Scripts">

<server
        name="irc.&networkDomain;"
        description="&networkName; IRC server"
        network="&networkName;">
<admin
       name="Admin"
       description="Supreme Overlord"
       email="irc@&networkDomain;">
<bind address="" port="6667" type="clients">
EOF

echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed InspIRCd"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/inspircd_${RELEASE}.deb12u1_amd64.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
