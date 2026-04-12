#!/usr/bin/env bash

# Copyright (c) 2021-2026 mitchscobell
# Author: mitchscobell
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ddclient.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing ddclient"
DEBIAN_FRONTEND=noninteractive $STD apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y ddclient
msg_ok "Installed ddclient"

msg_info "Creating ddclient service"
cat << EOF >/etc/ddclient.conf
protocol=namecheap
use=web, web=dynamicdns.park-your-domain.com/getip
protocol=namecheap
use=web, web=dynamicdns.park-your-domain.com/getip
server=dynamicdns.park-your-domain.com
login=yourdomain.com
password='your-ddns-password'
@,www
EOF
chmod 600 /etc/ddclient.conf
systemctl enable -q --now ddclient
msg_ok "Created ddclient service"

motd_ssh
customize
cleanup_lxc
