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

msg_info "Updating Python3"
$STD apt-get install -y \
  python3 \
  python3-dev \
  python3-pip
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Updated Python3"

msg_info "Installing Mailrise"
$STD pip install mailrise

mkdir -p /opt/mailrise
cat <<EOF >/opt/mailrise/mailrise.conf
configs:
  # You can send to this config with "basic_assistant@mailrise.xyz".
  #
  # The "-" is *very* important, even when configuring just a single URL.
  # Apprise requires urls to be a YAML *list*.
  #
  basic_assistant:
    urls:
      - hasio://HOST/ACCESS_TOKEN
  # You can send to this config with "telegram_and_discord@mailrise.xyz".
  #
  telegram_and_discord:
    urls:
      - tgram://MY_BOT_TOKEN
      - discord://WEBHOOK_ID/WEBHOOK_TOKEN
  
  # See https://github.com/YoRyan/mailrise?tab=readme-ov-file#sample-file for additional examples
 
EOF

cat <<EOF >/etc/systemd/system/mailrise.service
[Unit]
Description=Mailrise SMTP notification relay
After=network.target
[Service]
ExecStart=/usr/local/bin/mailrise /opt/mailrise/mailrise.conf
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now mailrise.service
msg_ok "Installed Mailrise"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
