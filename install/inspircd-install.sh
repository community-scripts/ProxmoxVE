#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.inspircd.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "inspircd" "inspircd/inspircd" "binary"

msg_info "Configuring InspIRCd"
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
msg_ok "Installed InspIRCd"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
