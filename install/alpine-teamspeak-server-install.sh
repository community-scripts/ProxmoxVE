#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021 (Slaviša Arežina)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://teamspeak.com/en/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apk add --no-cache \
  ca-certificates \
  libstdc++ \
  libc6-compat
msg_ok "Installed dependencies"

RELEASE=$(curl -fsSL https://teamspeak.com/en/downloads/#server | sed -n '/teamspeak3-server_linux_amd64-/ { s/.*teamspeak3-server_linux_amd64-\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p; q }')

msg_info "Installing Teamspeak Server v${RELEASE}"
mkdir -p /opt/teamspeak-server
cd /opt/teamspeak-server
curl -fsSL "https://files.teamspeak-services.com/releases/server/${RELEASE}/teamspeak3-server_linux_amd64-${RELEASE}.tar.bz2" -o ts3server.tar.bz2
tar xf ts3server.tar.bz2 --strip-components=1
mkdir -p logs data lib
mv *.so lib
touch data/ts3server.sqlitedb data/query_ip_blacklist.txt data/query_ip_whitelist.txt .ts3server_license_accepted
echo "${RELEASE}" >~/.teamspeak-server
msg_ok "Installed TeamSpeak Server v${RELEASE}"

msg_info "Enabling TeamSpeak Server Service"
cat <<EOF >/etc/init.d/teamspeak
#!/sbin/openrc-run

name="TeamSpeak Server"
description="TeamSpeak 3 Server"
command="/opt/teamspeak-server/ts3server_startscript.sh"
command_args="start"
output_log="/var/log/teamspeak.out.log"
error_log="/var/log/teamspeak.err.log"
command_background=true
pidfile="/run/teamspeak-server.pid"
directory="/opt/teamspeak-server"

depend() {
    need net
    use dns
}
EOF
chmod +x /etc/init.d/teamspeak
$STD rc-update add teamspeak default
msg_ok "Enabled TeamSpeak Server Service"

msg_info "Starting TeamSpeak Server"
$STD service teamspeak start
msg_ok "Started TeamSpeak Server"

motd_ssh
customize

msg_info "Cleaning up"
rm -r ts3server.tar.bz* LICENSE* CHANGELOG doc serverquerydocs tsdns redist
$STD apk cache clean
msg_ok "Cleaned"
