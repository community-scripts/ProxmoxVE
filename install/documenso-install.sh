#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/documenso/documenso

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  openssl \
  curl \
  gnupg
msg_ok "Installed Dependencies"

msg_info "Setup Docker Repository"
setup_deb822_repo \
  "docker" \
  "https://download.docker.com/linux/$(get_os_info id)/gpg" \
  "https://download.docker.com/linux/$(get_os_info id)" \
  "$(get_os_info codename)" \
  "stable" \
  "$(dpkg --print-architecture)"
msg_ok "Setup Docker Repository"

msg_info "Installing Docker"
$STD apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-compose-plugin
msg_ok "Installed Docker"

PG_VERSION="16" setup_postgresql
PG_DB_NAME="documenso" PG_DB_USER="documenso" setup_postgresql_db

msg_info "Generating Secrets"
NEXTAUTH_SECRET=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
ENCRYPTION_SECONDARY_KEY=$(openssl rand -hex 32)
CERT_PASSPHRASE=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | cut -c1-12)
msg_ok "Generated Secrets"

msg_info "Generating Signing Certificate"
mkdir -p /opt/documenso/certs

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /tmp/documenso.key \
  -out /tmp/documenso.crt \
  -subj "/C=US/ST=Self-Hosted/L=Proxmox/O=Documenso/CN=documenso.local" 2>/dev/null

openssl pkcs12 -export -legacy \
  -out /opt/documenso/certs/cert.p12 \
  -inkey /tmp/documenso.key \
  -in /tmp/documenso.crt \
  -passout "pass:${CERT_PASSPHRASE}" 2>/dev/null

rm -f /tmp/documenso.key /tmp/documenso.crt
chmod 644 /opt/documenso/certs/cert.p12
msg_ok "Generated Signing Certificate"

msg_info "Creating Configuration"
LOCAL_IP=$(hostname -I | awk '{print $1}')

cat <<EOF >/opt/documenso/.env
# Documenso Environment Configuration
PORT=3000
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
NEXT_PRIVATE_ENCRYPTION_KEY=${ENCRYPTION_KEY}
NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY=${ENCRYPTION_SECONDARY_KEY}
NEXT_PUBLIC_WEBAPP_URL=http://${LOCAL_IP}:3000
NEXT_PRIVATE_DATABASE_URL=postgres://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}
NEXT_PRIVATE_DIRECT_DATABASE_URL=postgres://${PG_DB_USER}:${PG_DB_PASS}@127.0.0.1:5432/${PG_DB_NAME}
NEXT_PUBLIC_UPLOAD_TRANSPORT=database
NEXT_PRIVATE_SMTP_TRANSPORT=smtp-auth
NEXT_PRIVATE_SMTP_FROM_NAME=Documenso
NEXT_PRIVATE_SMTP_FROM_ADDRESS=noreply@documenso.local
NEXT_PRIVATE_SIGNING_LOCAL_FILE_PATH=/opt/documenso/cert.p12
NEXT_PRIVATE_SIGNING_PASSPHRASE=${CERT_PASSPHRASE}
DOCUMENSO_DISABLE_TELEMETRY=true
EOF

chmod 600 /opt/documenso/.env
msg_ok "Created Configuration"

{
  echo "Documenso Credentials"
  echo "====================="
  echo ""
  echo "Web URL: http://${LOCAL_IP}:3000"
  echo ""
  echo "PostgreSQL:"
  echo "  Database: ${PG_DB_NAME}"
  echo "  User: ${PG_DB_USER}"
  echo "  Password: ${PG_DB_PASS}"
  echo ""
  echo "Certificate Passphrase: ${CERT_PASSPHRASE}"
  echo ""
  echo "Configuration: /opt/documenso/.env"
  echo ""
  echo "Note: Configure SMTP settings in .env for email verification"
} >~/documenso.creds
msg_ok "Saved Credentials to ~/documenso.creds"

msg_info "Starting Documenso"
$STD docker pull documenso/documenso:latest
$STD docker run -d \
  --name documenso \
  --restart unless-stopped \
  --network host \
  --log-driver journald \
  --env-file /opt/documenso/.env \
  -v /opt/documenso/certs/cert.p12:/opt/documenso/cert.p12:ro \
  documenso/documenso:latest

# Wait for container to be ready
sleep 5

# Save version
docker inspect documenso --format '{{.Config.Image}}' | cut -d: -f2 >/opt/documenso/.version
msg_ok "Started Documenso"

motd_ssh
customize
cleanup_lxc
