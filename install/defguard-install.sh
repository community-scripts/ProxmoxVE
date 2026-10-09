#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DefGuard/defguard

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PG_VERSION="17" setup_postgresql
PG_DB_NAME="defguard" PG_DB_USER="defguard" setup_postgresql_db

setup_deb822_repo \
  "defguard" \
  "https://apt.defguard.net/defguard.asc" \
  "https://apt.defguard.net" \
  "$(get_os_info codename)" \
  "release-2.0"

msg_info "Installing Defguard"
$STD apt install -y defguard
msg_ok "Installed Defguard"

msg_info "Configuring Defguard"
DEFGUARD_ADMIN_PASSWORD=$(openssl rand -base64 18)
cat <<EOF >/etc/defguard/core.conf
DEFGUARD_DB_HOST=localhost
DEFGUARD_DB_PORT=5432
DEFGUARD_DB_NAME=defguard
DEFGUARD_DB_USER=defguard
DEFGUARD_DB_PASSWORD=${PG_DB_PASS}

DEFGUARD_URL=http://${LOCAL_IP}:8000
DEFGUARD_HTTP_PORT=8000
DEFGUARD_GRPC_PORT=50055

DEFGUARD_DEFAULT_ADMIN_PASSWORD=${DEFGUARD_ADMIN_PASSWORD}
DEFGUARD_COOKIE_INSECURE=true
DEFGUARD_LOG_LEVEL=info
EOF
chown root:defguard /etc/defguard/core.conf
chmod 640 /etc/defguard/core.conf
systemctl restart defguard
msg_ok "Configured Defguard"

msg_info "Installing Defguard Edge"
$STD apt install -y defguard-proxy
mkdir -p /etc/defguard/certs
cat <<EOF >/etc/defguard/proxy.toml
# Defguard Edge (proxy) configuration
# Apply changes with: systemctl restart defguard-proxy

# Port the API/enrollment HTTP server listens on
http_port = 8080
# Port the HTTPS server listens on (used after Core provisions TLS)
https_port = 8443
# Port the gRPC server listens on. Core connects here to adopt and manage the Edge.
grpc_port = 50051
# Directory where adoption-provisioned mTLS certificates are stored
cert_dir = "/etc/defguard/certs"

log_level = "info"
rate_limit_per_second = 0
rate_limit_burst = 0
EOF
chown -R defguard:defguard /etc/defguard/certs /etc/defguard/proxy.toml
systemctl enable -q --now defguard-proxy
msg_ok "Installed Defguard Edge"

motd_ssh
customize
cleanup_lxc
