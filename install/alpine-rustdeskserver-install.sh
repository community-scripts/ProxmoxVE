#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rustdesk/rustdesk-server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

RELEASE=$(curl -s https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
msg_info "Installing RustDesk Server v${RELEASE}"
temp_file1=$(mktemp)
curl -fsSL "https://github.com/rustdesk/rustdesk-server/releases/download/${RELEASE}/rustdesk-server-linux-amd64.zip" -o "$temp_file1"
$STD unzip "$temp_file1"
mv amd64 /opt/rustdesk-server
mkdir -p /root/.config/rustdesk
cd /opt/rustdesk-server
./rustdesk-utils genkeypair > /tmp/rustdesk_keys.txt
grep "Public Key" /tmp/rustdesk_keys.txt | awk '{print $3}' > /root/.config/rustdesk/id_ed25519.pub
grep "Secret Key" /tmp/rustdesk_keys.txt | awk '{print $3}' > /root/.config/rustdesk/id_ed25519
chmod 600 /root/.config/rustdesk/id_ed25519
chmod 644 /root/.config/rustdesk/id_ed25519.pub
rm /tmp/rustdesk_keys.txt
echo "${RELEASE}" >~/.rustdesk-server
msg_ok "Installed RustDesk Server v${RELEASE}"

APIRELEASE=$(curl -s https://api.github.com/repos/lejianwen/rustdesk-api/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
msg_info "Installing RustDesk API v${APIRELEASE}"
temp_file2=$(mktemp)
curl -fsSL "https://github.com/lejianwen/rustdesk-api/releases/download/v${APIRELEASE}/linux-amd64.tar.gz" -o "$temp_file2"
$STD tar zxvf "$temp_file2"
mv release /opt/rustdesk-api
cd /opt/rustdesk-api
ADMINPASS=$(head -c 16 /dev/urandom | xxd -p -c 16)
$STD ./apimain reset-admin-pwd "$ADMINPASS"
{
  echo "RustDesk WebUI"
  echo ""
  echo "Username: admin"
  echo "Password: $ADMINPASS"
} >>~/rustdesk.creds
echo "${APIRELEASE}" >~/.rustdesk-api
msg_ok "Installed RustDesk API v${APIRELEASE}"

msg_info "Enabling RustDesk Server Services"
cat <<EOF >/etc/init.d/rustdesk-server-hbbs
#!/sbin/openrc-run
description="RustDesk HBBS Service"
directory="/opt/rustdesk-server"
command="/opt/rustdesk-server/hbbs"
command_args=""
command_background="true"
command_user="root"
pidfile="/var/run/rustdesk-server-hbbs.pid"
output_log="/var/log/rustdesk-hbbs.log"
error_log="/var/log/rustdesk-hbbs.err"

depend() {
    use net
}
EOF

cat <<EOF >/etc/init.d/rustdesk-server-hbbr
#!/sbin/openrc-run
description="RustDesk HBBR Service"
directory="/opt/rustdesk-server"
command="/opt/rustdesk-server/hbbr"
command_args=""
command_background="true"
command_user="root"
pidfile="/var/run/rustdesk-server-hbbr.pid"
output_log="/var/log/rustdesk-hbbr.log"
error_log="/var/log/rustdesk-hbbr.err"

depend() {
    use net
}
EOF

cat <<EOF >/etc/init.d/rustdesk-api
#!/sbin/openrc-run
description="RustDesk API Service"
directory="/opt/rustdesk-api"
command="/opt/rustdesk-api/apimain"
command_args=""
command_background="true"
command_user="root"
pidfile="/var/run/rustdesk-api.pid"
output_log="/var/log/rustdesk-api.log"
error_log="/var/log/rustdesk-api.err"

depend() {
    use net
}
EOF
chmod +x /etc/init.d/rustdesk-server-hbbs
chmod +x /etc/init.d/rustdesk-server-hbbr
chmod +x /etc/init.d/rustdesk-api
$STD rc-update add rustdesk-server-hbbs default
$STD rc-update add rustdesk-server-hbbr default
$STD rc-update add rustdesk-api default
msg_ok "Enabled RustDesk Server Services"

msg_info "Starting RustDesk Server"
$STD service rustdesk-server-hbbs start
$STD service rustdesk-server-hbbr start
$STD service rustdesk-api start
msg_ok "Started RustDesk Server"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file1" "$temp_file2"
$STD apk cache clean
msg_ok "Cleaned"
