#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://adguardhome.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Downloading AdGuard Home"
$STD curl -fsSL -o /tmp/AdGuardHome_linux_amd64.tar.gz \
  "https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_amd64.tar.gz"
msg_ok "Downloaded AdGuard Home"

msg_info "Installing AdGuard Home"
$STD tar -xzf /tmp/AdGuardHome_linux_amd64.tar.gz -C /opt
$STD rm /tmp/AdGuardHome_linux_amd64.tar.gz
msg_ok "Installed AdGuard Home"

msg_info "Creating AdGuard Home Service"
cat <<EOF >/etc/init.d/adguardhome
#!/sbin/openrc-run
name="AdGuardHome"
description="AdGuard Home Service"
command="/opt/AdGuardHome/AdGuardHome"
command_background="yes"
pidfile="/run/adguardhome.pid"
EOF
$STD chmod +x /etc/init.d/adguardhome
msg_ok "Created AdGuard Home Service"

msg_info "Enabling AdGuard Home Service"
$STD rc-update add adguardhome default
msg_ok "Enabled AdGuard Home Service"

msg_info "Starting AdGuard Home"
$STD rc-service adguardhome start
msg_ok "Started AdGuard Home"

motd_ssh
customize
