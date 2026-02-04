#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://aria2.github.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Aria2"
$STD apt install -y aria2
msg_ok "Installed Aria2"

read -r -p "${TAB3}Would you like to add AriaNG? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing Dependencies"
  $STD apt install -y nginx
  systemctl disable -q --now nginx
  rm /etc/nginx/sites-enabled/*
  msg_ok "Installed Dependencies"

  fetch_and_deploy_gh_release "ariang" "mayswind/ariang" "prebuild" "latest" "/var/www" "AriaNg-*-AllInOne.zip"
  
  msg_info "Configure nginx"
  cat <<EOF >/etc/nginx/conf.d/ariang.conf
server {
    listen 6880 default_server;
    listen [::]:6880 default_server;

    server_name _;

    root /var/www;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
  cp /lib/systemd/system/nginx.service /lib/systemd/system/ariang.service
  systemctl enable -q --now ariang
  msg_ok "Configured nginx"
fi

msg_info "Creating Service"
mkdir -p /root/downloads
rpc_secret=$(openssl rand -base64 8)
echo "rpc-secret: $rpc_secret" >>~/rpc.secret
cat <<EOF >/root/aria2.daemon
dir=/root/downloads
file-allocation=falloc
max-connection-per-server=4
max-concurrent-downloads=2
max-overall-download-limit=0
min-split-size=25M
rpc-allow-origin-all=true
rpc-secret=${rpc_secret}
input-file=/var/tmp/aria2c.session
save-session=/var/tmp/aria2c.session
EOF

cat <<EOF >/etc/systemd/system/aria2.service
[Unit]
Description=Aria2c download manager
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStartPre=/usr/bin/env touch /var/tmp/aria2c.session
ExecStart=/usr/bin/aria2c --console-log-level=warn --enable-rpc --rpc-listen-all --conf-path=/root/aria2.daemon
TimeoutStopSec=20
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now aria2
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
