#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
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
    wget \
    mc 
msg_ok "Installed Dependencies"


msg_info "Installing Glance"
RELEASE=$(curl -s https://api.github.com/repos/glanceapp/glance/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
cd /opt
wget -q https://github.com/glanceapp/glance/releases/download/v${RELEASE}/glance-linux-amd64.tar.gz
mkdir /opt/glance
tar -xzf glance-linux-amd64.tar.gz -C /opt/glance
cat <<EOF >/opt/glance/glance.yml
pages:
  - name: Startpage
    width: slim
    hide-desktop-navigation: true
    center-vertically: true
    columns:
      - size: full
        widgets:
          - type: search
            autofocus: true

          - type: monitor
            cache: 1m
            title: Services
            sites:
              - title: Jellyfin
                url: https://yourdomain.com/
                icon: si:jellyfin
              - title: Gitea
                url: https://yourdomain.com/
                icon: si:gitea
              - title: qBittorrent # only for Linux ISOs, of course
                url: https://yourdomain.com/
                icon: si:qbittorrent
              - title: Immich
                url: https://yourdomain.com/
                icon: si:immich
              - title: AdGuard Home
                url: https://yourdomain.com/
                icon: si:adguard
              - title: Vaultwarden
                url: https://yourdomain.com/
                icon: si:vaultwarden

          - type: bookmarks
            groups:
              - title: General
                links:
                  - title: Gmail
                    url: https://mail.google.com/mail/u/0/
                  - title: Amazon
                    url: https://www.amazon.com/
                  - title: Github
                    url: https://github.com/
              - title: Entertainment
                links:
                  - title: YouTube
                    url: https://www.youtube.com/
                  - title: Prime Video
                    url: https://www.primevideo.com/
                  - title: Disney+
                    url: https://www.disneyplus.com/
              - title: Social
                links:
                  - title: Reddit
                    url: https://www.reddit.com/
                  - title: Twitter
                    url: https://twitter.com/
                  - title: Instagram
                    url: https://www.instagram.com/
EOF

echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Glance"

msg_info "Creating Service"
service_path="/etc/systemd/system/glance.service"
echo "[Unit]
Description=Glance Daemon
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/glance
ExecStart=/opt/glance/glance --config /opt/glance/glance.yml
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target" >$service_path

systemctl enable --now -q glance.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/glance-linux-amd64.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
