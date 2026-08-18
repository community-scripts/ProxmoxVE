#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://traefik.io/ | Github: https://github.com/traefik/traefik

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_deb_based() {
  msg_info "Installing Dependencies"
  $STD apt install -y apt-transport-https
  msg_ok "Installed Dependencies"

  fetch_and_deploy_gh_release "traefik" "traefik/traefik" "prebuild" "latest" "/usr/bin" "traefik_v*_linux_$(arch_resolve).tar.gz"
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
}

setup_alpine() {
  msg_info "Installing Dependencies"
  $STD apk add ca-certificates
  $STD update-ca-certificates
  msg_ok "Installed Dependencies"

  msg_info "Installing Traefik"
  $STD apk add traefik --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
  msg_ok "Installed Traefik"

  read -p "${TAB3}Enable Traefik WebUI (Port 8080)? [y/N]: " enable_webui
  if [[ "$enable_webui" =~ ^[Yy]$ ]]; then
    msg_info "Configuring Traefik WebUI"
    sed -i 's/localhost//g' /etc/traefik/traefik.yaml
    msg_ok "Configured Traefik WebUI"
  fi

  msg_info "Enabling and starting Traefik service"
  $STD rc-update add traefik default
  sed -i '/^command=.*/i directory="/etc/traefik"' /etc/init.d/traefik
  $STD rc-service traefik start
  msg_ok "Traefik service started"
}

run_os_setup

motd_ssh
customize
cleanup_lxc
