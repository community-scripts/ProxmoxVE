#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

msg_info "Installing Aria2"
$STD apt-get install -y aria2
msg_ok "Installed Aria2"

read -r -p "Would you like to add AriaNG? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  msg_info "Installing AriaNG"
  $STD apt-get install -y nginx
  systemctl disable -q --now nginx
  wget -q "$(curl -s https://api.github.com/repos/mayswind/ariang/releases/latest | grep download | grep AllInOne.zip | cut -d\" -f4)"
  $STD unzip AriaNg-*-AllInOne.zip -d /var/www
  rm /etc/nginx/sites-enabled/*
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
  msg_ok "Installed AriaNG"
fi

msg_info "Creating Service"
mkdir /root/downloads
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
systemctl enable -q --now aria2.service
systemctl enable -q --now ariang
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm AriaNg-*-AllInOne.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"