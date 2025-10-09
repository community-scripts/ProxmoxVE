#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://traefik.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y apt-transport-https
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "traefik" "traefik/traefik" "prebuild" "latest" "/usr/bin" "traefik_v*_linux_amd64.tar.gz"
mkdir -p /etc/traefik/{conf.d,ssl}

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
cat <<'EOF' >/etc/systemd/system/traefik.service
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
systemctl enable -q --now traefik
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
