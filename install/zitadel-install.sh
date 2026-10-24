#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: dave-yap (dave-yap) | Co-Author: remz1337, MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zitadel.com/ | Github: https://github.com/zitadel/zitadel

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

var_zitadel_login="${var_zitadel_login:-v2}"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="zitadel" PG_DB_USER="zitadel" setup_postgresql_db
fetch_and_deploy_gh_release "zitadel" "zitadel/zitadel" "prebuild" "latest" "/usr/local/bin" "zitadel-linux-$(arch_resolve).tar.gz"

msg_info "Configuring Zitadel"
mkdir -p /opt/zitadel
random_password 32 >/opt/zitadel/.masterkey
ADMIN_PASS="$(random_password 20)Aa1!"
cat <<EOF >/opt/zitadel/config.yaml
ExternalDomain: ${LOCAL_IP}
ExternalPort: 8080
TLS:
  Enabled: false
Database:
  postgres:
    Host: localhost
    Port: 5432
    Database: zitadel
    User:
      Username: zitadel
      Password: ${PG_DB_PASS}
      SSL:
        Mode: disable
Machine:
  Identification:
    Hostname:
      Enabled: true
EOF
if [[ "$var_zitadel_login" == "v1" ]]; then
  cat <<EOF >>/opt/zitadel/config.yaml
Port: 8080
ExternalSecure: false
DefaultInstance:
  Features:
    LoginV2:
      Required: false
FirstInstance:
  Org:
    Human:
      UserName: zitadel-admin@zitadel.localhost
      Password: ${ADMIN_PASS}
      PasswordChangeRequired: true
EOF
else
  cat <<EOF >>/opt/zitadel/config.yaml
Port: 8081
ExternalSecure: true
DefaultInstance:
  Features:
    LoginV2:
      Required: true
FirstInstance:
  LoginClientPatPath: /opt/zitadel/login-client.pat
  Org:
    Human:
      UserName: zitadel-admin@zitadel.localhost
      Password: ${ADMIN_PASS}
      PasswordChangeRequired: true
    LoginClient:
      Machine:
        Username: login-client
        Name: Automatically Initialized IAM_LOGIN_CLIENT
      Pat:
        ExpirationDate: 2099-01-01T00:00:00Z
EOF
fi
chmod 600 /opt/zitadel/.masterkey /opt/zitadel/config.yaml
msg_ok "Configured Zitadel"

msg_info "Initializing Zitadel"
$STD zitadel init zitadel --config /opt/zitadel/config.yaml
$STD zitadel setup --masterkeyFile /opt/zitadel/.masterkey --config /opt/zitadel/config.yaml --steps /opt/zitadel/config.yaml
cat <<EOF >>~/zitadel.creds

Zitadel Admin
Username: zitadel-admin@zitadel.localhost
Initial Password: ${ADMIN_PASS}
EOF
chmod 600 ~/zitadel.creds
msg_ok "Initialized Zitadel"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/zitadel.service
[Unit]
Description=Zitadel
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
ExecStart=/usr/local/bin/zitadel start --masterkeyFile /opt/zitadel/.masterkey --config /opt/zitadel/config.yaml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now zitadel
msg_ok "Created Service"

if [[ "$var_zitadel_login" != "v1" ]]; then
  NODE_VERSION="24" setup_nodejs
  fetch_and_deploy_gh_release "zitadel-login" "zitadel/zitadel" "prebuild" "latest" "/opt/zitadel-login" "zitadel-login.tar.gz"

  msg_info "Setting up Zitadel Login"
  $STD apt install -y nginx
  create_self_signed_cert "zitadel"
  cat <<EOF >/opt/zitadel/login.env
ZITADEL_API_URL=http://127.0.0.1:8081
ZITADEL_API_AWAITINITIALCONN=5m
ZITADEL_SERVICE_USER_TOKEN_FILE=/opt/zitadel/login-client.pat
ZITADEL_SESSION_COOKIE_SECRET=$(random_password 48)
NEXT_PUBLIC_BASE_PATH=/ui/v2/login
HOSTNAME=127.0.0.1
PORT=3000
EOF
  chmod 600 /opt/zitadel/login.env /opt/zitadel/login-client.pat
  cat <<EOF >/etc/systemd/system/zitadel-login.service
[Unit]
Description=Zitadel Login
After=network.target zitadel.service
Wants=zitadel.service

[Service]
Type=simple
WorkingDirectory=/opt/zitadel-login
EnvironmentFile=/opt/zitadel/login.env
ExecStart=/opt/zitadel-login/entrypoint.sh node apps/login/server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now zitadel-login
  cat <<'EOF' >/etc/nginx/sites-available/zitadel
server {
    listen 8080 ssl;
    http2 on;
    server_name _;
    ssl_certificate /etc/ssl/zitadel/zitadel.crt;
    ssl_certificate_key /etc/ssl/zitadel/zitadel.key;
    error_page 497 =301 https://$http_host$request_uri;

    location = / {
        return 302 /ui/v2/login/;
    }

    location /ui/v2/login {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ {
        rewrite ^/api(/.*)$ $1 break;
        grpc_pass grpc://127.0.0.1:8081;
        grpc_set_header Host $http_host;
    }

    location / {
        grpc_pass grpc://127.0.0.1:8081;
        grpc_set_header Host $http_host;
    }
}
EOF
  nginx_enable_site "zitadel"
  msg_ok "Set up Zitadel Login"
fi

motd_ssh
customize
cleanup_lxc
