#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-author: Rogue-King
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
$STD apt-get install -y git
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y sqlite3
msg_ok "Installed Dependencies"

msg_info "Installing Gitea"
RELEASE=$(wget -q https://github.com/go-gitea/gitea/releases/latest -O - | grep "title>Release" | cut -d " " -f 4 | sed 's/^v//')
wget -q https://github.com/go-gitea/gitea/releases/download/v$RELEASE/gitea-$RELEASE-linux-amd64
mv gitea* /usr/local/bin/gitea
chmod +x /usr/local/bin/gitea
adduser --system --group --disabled-password --shell /bin/bash --home /etc/gitea gitea > /dev/null
mkdir -p /var/lib/gitea/{custom,data,log}
chown -R gitea:gitea /var/lib/gitea/
chmod -R 750 /var/lib/gitea/
chown root:gitea /etc/gitea
chmod 770 /etc/gitea
sudo -u gitea ln -s /var/lib/gitea/data/.ssh/ /etc/gitea/.ssh
msg_ok "Installed Gitea"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/gitea.service
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target

[Service]
# Uncomment notify and watchdog if you want to use them
# Uncomment the next line if you have repos with lots of files and get a HTTP 500 error because of that
# LimitNOFILE=524288:524288
RestartSec=2s
Type=simple
#Type=notify
User=gitea
Group=gitea
#The mount point we added to the container
WorkingDirectory=/var/lib/gitea
#Create directory in /run
RuntimeDirectory=gitea
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
Environment=USER=gitea HOME=/var/lib/gitea/data GITEA_WORK_DIR=/var/lib/gitea
#WatchdogSec=30s
#Capabilities to bind to low-numbered ports
#CapabilityBoundingSet=CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gitea
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
