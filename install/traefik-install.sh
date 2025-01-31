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
$STD apt-get install -y gpg
$STD apt-get install -y apt-transport-https
msg_ok "Installed Dependencies"

RELEASE=$(curl -s https://api.github.com/repos/traefik/traefik/releases | grep -oP '"tag_name":\s*"v\K[\d.]+?(?=")' | sort -V | tail -n 1)
msg_info "Installing Traefik v${RELEASE}"
mkdir -p /etc/traefik/{conf.d,ssl}
wget -q https://github.com/traefik/traefik/releases/download/v${RELEASE}/traefik_v${RELEASE}_linux_amd64.tar.gz
tar -C /tmp -xzf traefik*.tar.gz
mv /tmp/traefik /usr/bin/
rm -rf traefik*.tar.gz
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Traefik v${RELEASE}"

msg_info "Creating Traefik configuration"
cat <<EOF >/etc/traefik/traefik.yaml
providers:
  file:
    directory: /etc/traefik/conf.d/

entryPoints:
  web:
    address: ':80'
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ':443'
    http:
      tls:
        certResolver: letsencrypt
  traefik:
    address: ':8080'

certificatesResolvers:
  letsencrypt:
    acme:
      email: "foo@bar.com"
      storage: /etc/traefik/ssl/acme.json
      tlsChallenge: {}

api:
  dashboard: true
  insecure: true

log:
  filePath: /var/log/traefik/traefik.log
  format: json
  level: INFO

accessLog:
  filePath: /var/log/traefik/traefik-access.log
  format: json
  filters:
    statusCodes:
      - "200"
      - "400-599"
    retryAttempts: true
    minDuration: "10ms"
  bufferingSize: 0
  fields:
    headers:
      defaultMode: drop
      names:
        User-Agent: keep
EOF
msg_ok "Created Traefik configuration"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/traefik.service
[Unit]
Description=Traefik is an open-source Edge Router that makes publishing your services a fun and easy experience

[Service]
Type=notify
ExecStart=/usr/bin/traefik --configFile=/etc/traefik/traefik.yaml
Restart=on-failure
ExecReload=/bin/kill -USR1 \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now traefik.service
msg_ok "Created Service"


motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
