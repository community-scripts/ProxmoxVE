#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://pangolin.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  sqlite3 \
  iptables
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "pangolin" "fosrl/pangolin" "tarball"
fetch_and_deploy_gh_release "gerbil" "fosrl/gerbil" "singlefile" "latest" "/usr/bin" "gerbil_linux_amd64"
fetch_and_deploy_gh_release "traefik" "traefik/traefik" "prebuild" "latest" "/usr/bin" "traefik_v*_linux_amd64.tar.gz"

read -rp "${TAB3}Enter your Pangolin URL (ex: https://pangolin.example.com): " pango_url
read -rp "${TAB3}Enter your email address: " pango_email

msg_info "Setup Pangolin"
SECRET_KEY=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32)
BADGER_VERSION=$(get_latest_github_release "fosrl/badger" "false")
cd /opt/pangolin
mkdir -p /opt/pangolin/config/{traefik,db,letsencrypt,logs}
$STD npm ci
$STD npm run set:sqlite
$STD npm run set:oss
rm -rf server/private
$STD npm run db:generate
$STD npm run build
$STD npm run build:cli
cp -R .next/standalone ./

cat <<EOF >/usr/local/bin/pangctl
#!/bin/sh
cd /opt/pangolin
./dist/cli.mjs "$@"
EOF
chmod +x /usr/local/bin/pangctl ./dist/cli.mjs
cp server/db/names.json ./dist/names.json
cp server/db/ios_models.json ./dist/ios_models.json
cp server/db/mac_models.json ./dist/mac_models.json
mkdir -p /var/config

cat <<EOF >/opt/pangolin/config/config.yml
app:
  dashboard_url: "$pango_url"

domains:
  domain1:
    base_domain: "$pango_url"
    cert_resolver: "letsencrypt"

server:
  secret: "$SECRET_KEY"

gerbil:
  base_endpoint: "${pango_url#https://}"

flags:
  require_email_verification: false
  disable_signup_without_invite: false
  disable_user_create_org: false
EOF

cat <<EOF >/opt/pangolin/config/traefik/traefik_config.yml
api:
  insecure: true
  dashboard: true

providers:
  http:
    endpoint: "http://$LOCAL_IP:3001/api/v1/traefik-config"
    pollInterval: "5s"
  file:
    filename: "/opt/pangolin/config/traefik/dynamic_config.yml"

experimental:
  plugins:
    badger:
      moduleName: "github.com/fosrl/badger"
      version: "$BADGER_VERSION"

log:
  level: "INFO"
  format: "common"

certificatesResolvers:
  letsencrypt:
    acme:
      httpChallenge:
        entryPoint: web
      email: $pango_email
      storage: "/opt/pangolin/config/letsencrypt/acme.json"
      caServer: "https://acme-v02.api.letsencrypt.org/directory"

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
    transport:
      respondingTimeouts:
        readTimeout: "30m"
    http:
      tls:
        certResolver: "letsencrypt"

serversTransport:
  insecureSkipVerify: true

ping:
    entryPoint: "web"
EOF

cat <<EOF >/opt/pangolin/config/traefik/dynamic_config.yml
http:
  middlewares:
    redirect-to-https:
      redirectScheme:
        scheme: https

  routers:
    # HTTP to HTTPS redirect router
    main-app-router-redirect:
      rule: "Host(\`${pango_url#https://}\`)"
      service: next-service
      entryPoints:
        - web
      middlewares:
        - redirect-to-https

    # Next.js router (handles everything except API and WebSocket paths)
    next-router:
      rule: "Host(\`${pango_url#https://}\`) && !PathPrefix(\`/api/v1\`)"
      service: next-service
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt

    # API router (handles /api/v1 paths)
    api-router:
      rule: "Host(\`${pango_url#https://}\`) && PathPrefix(\`/api/v1\`)"
      service: api-service
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt

    # WebSocket router
    ws-router:
      rule: "Host(\`${pango_url#https://}\`)"
      service: api-service
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt

  services:
    next-service:
      loadBalancer:
        servers:
          - url: "http://$LOCAL_IP:3002"

    api-service:
      loadBalancer:
        servers:
          - url: "http://$LOCAL_IP:3000"
EOF
$STD npm run db:sqlite:push

. /etc/os-release
if [ "$VERSION_CODENAME" = "trixie" ]; then
  echo "net.ipv4.ip_forward=1" >>/etc/sysctl.d/sysctl.conf
  $STD sysctl -p /etc/sysctl.d/sysctl.conf
else
  echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf
  $STD sysctl -p /etc/sysctl.conf
fi
msg_ok "Setup Pangolin"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/pangolin.service
[Unit]
Description=Pangolin Service
After=network.target

[Service]
Type=simple
User=root
Environment=NODE_ENV=production
Environment=ENVIRONMENT=prod
WorkingDirectory=/opt/pangolin
ExecStart=/usr/bin/node --enable-source-maps dist/server.mjs
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pangolin

cat <<EOF >/etc/systemd/system/gerbil.service
[Unit]
Description=Gerbil Service
After=network.target
Requires=pangolin.service

[Service]
Type=simple
User=root
ExecStart=/usr/bin/gerbil --reachableAt=http://$LOCAL_IP:3004 --generateAndSaveKeyTo=/var/config/key --remoteConfig=http://$LOCAL_IP:3001/api/v1/
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gerbil

cat <<'EOF' >/etc/systemd/system/traefik.service
[Unit]
Description=Traefik is an open-source Edge Router that makes publishing your services a fun and easy experience
Wants=network-online.target
After=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/traefik --configFile=/opt/pangolin/config/traefik/traefik_config.yml
Restart=on-failure
ExecReload=/bin/kill -USR1 \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now traefik
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
