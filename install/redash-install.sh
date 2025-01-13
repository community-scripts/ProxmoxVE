#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

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
  git \
  sudo \
  mc \
  apt-transport-https \
  ca-certificates \
  software-properties-common \
  gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

cat <<EOF >/etc/apt/sources.list.d/docker.list
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable
EOF

$STD apt-get update -y
$STD apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
msg_ok "Installed Dependencies"

msg_info "Creating directories needed by Redash"
mkdir -p /opt/redash
chown "$USER:" /opt/redash
msg_ok "Created directories needed for Redash"

msg_info "Creating Redash environment file"
COOKIE_SECRET=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
SECRET_KEY=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
PG_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
DATABASE_URL="postgresql://postgres:${PG_PASSWORD}@postgres/postgres"

cat <<EOF >/opt/redash/env
PYTHONUNBUFFERED=0
REDASH_LOG_LEVEL=INFO
REDASH_REDIS_URL=redis://redis:6379/0
REDASH_COOKIE_SECRET=$COOKIE_SECRET
REDASH_SECRET_KEY=$SECRET_KEY
POSTGRES_PASSWORD=$PG_PASSWORD
REDASH_DATABASE_URL=$DATABASE_URL
REDASH_ENFORCE_CSRF=true
REDASH_GUNICORN_TIMEOUT=60
EOF
msg_ok "Created Redash environment file"

msg_info "Creating Redash compose file"
cat <<EOF >/opt/redash/compose.yaml
x-redash-service: &redash-service
  image: redash/redash:25.1.0
  depends_on:
    - postgres
    - redis
  env_file: /opt/redash/env
  restart: always
services:
  server:
    <<: *redash-service
    command: server
    ports:
      - "5000:5000"
    environment:
      REDASH_WEB_WORKERS: 4
  scheduler:
    <<: *redash-service
    command: scheduler
    depends_on:
      - server
  scheduled_worker:
    <<: *redash-service
    command: worker
    depends_on:
      - server
    environment:
      QUEUES: "scheduled_queries,schemas"
      WORKERS_COUNT: 1
  adhoc_worker:
    <<: *redash-service
    command: worker
    depends_on:
      - server
    environment:
      QUEUES: "queries"
      WORKERS_COUNT: 2
  redis:
    image: redis:7-alpine
    restart: unless-stopped
  postgres:
    image: pgautoupgrade/pgautoupgrade:latest
    env_file: /opt/redash/env
    volumes:
      - /opt/redash/postgres-data:/var/lib/postgresql/data
    restart: unless-stopped
  nginx:
    image: redash/nginx:latest
    ports:
      - "80:80"
    depends_on:
      - server
    links:
      - server:redash
    restart: always
  worker:
    <<: *redash-service
    command: worker
    environment:
      QUEUES: "periodic,emails,default"
      WORKERS_COUNT: 1
EOF
msg_ok "Created Redash compose file"

msg_info "Installing Redash"
cd /opt/redash
$STD docker compose run --rm server create_db
$STD docker compose up -d
msg_ok "Installed Redash"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
