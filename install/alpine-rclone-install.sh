#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rclone/rclone

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing dependencies"
$STD apk add --no-cache \
  apache2-utils fuse3
msg_ok "Installed dependencies"

msg_info "Installing rclone"
temp_file=$(mktemp)
mkdir -p /opt/rclone
RELEASE=$(curl -s https://api.github.com/repos/rclone/rclone/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/rclone/rclone/releases/download/v${RELEASE}/rclone-v${RELEASE}-linux-amd64.zip" -o "$temp_file"
$STD unzip -j "$temp_file" '*/**' -d /opt/rclone
cd /opt/rclone
RCLONE_PASSWORD=$(head -c 16 /dev/urandom | xxd -p -c 16)
$STD htpasswd -cb -B /opt/login.pwd admin "$RCLONE_PASSWORD"
{
  echo "rclone-Credentials"
  echo "rclone User Name: admin"
  echo "rclone Password: $RCLONE_PASSWORD"
} >>~/rclone.creds
echo "${RELEASE}" >/opt/rclone_version.txt
rm -f "$temp_file"
msg_ok "Installed rclone"

msg_info "Enabling rclone Service"
cat <<EOF >/etc/init.d/rclone
#!/sbin/openrc-run
description="rclone Service"
command="/opt/rclone/rclone"
command_args="rcd --rc-web-gui --rc-web-gui-no-open-browser --rc-addr :3000 --rc-htpasswd /opt/login.pwd"
command_background="true"
command_user="root"
pidfile="/var/run/rclone.pid"

depend() {
    use net
}
EOF
chmod +x /etc/init.d/rclone
$STD rc-update add rclone default
msg_ok "Enabled rclone Service"

msg_info "Starting rclone"
$STD service rclone start
msg_ok "Started rclone"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "$temp_file"
$STD apk cache clean
msg_ok "Cleaned"
