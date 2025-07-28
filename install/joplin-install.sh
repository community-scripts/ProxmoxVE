#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: alvaroalonso
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://joplinapp.org/

source /dev/stdin <<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

APPLICATION="joplin"

msg_info "Installing Dependencies"
$STD apt-get install -y curl wget gnupg2 apt-transport-https ca-certificates software-properties-common
msg_ok "Installed Dependencies"

# Install Docker
msg_info "Installing Docker"
$STD curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
$STD echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
$STD apt-get update
$STD apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
$STD systemctl enable --now docker
msg_ok "Installed Docker"

# Create Joplin Server directory
msg_info "Setting up Joplin Server"
$STD mkdir -p /opt/joplin
$STD cd /opt/joplin

# Create docker-compose.yml file
cat > /opt/joplin/docker-compose.yml <<'EOF'
version: '3'

services:
  db:
    image: postgres:13
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    restart: unless-stopped
    environment:
      - POSTGRES_PASSWORD=joplin
      - POSTGRES_USER=joplin
      - POSTGRES_DB=joplin

  joplin:
    image: joplin/server:latest
    depends_on:
      - db
    ports:
      - "22300:22300"
    restart: unless-stopped
    environment:
      - APP_PORT=22300
      - APP_BASE_URL=http://localhost:22300
      - DB_CLIENT=pg
      - POSTGRES_PASSWORD=joplin
      - POSTGRES_DATABASE=joplin
      - POSTGRES_USER=joplin
      - POSTGRES_PORT=5432
      - POSTGRES_HOST=db
    volumes:
      - ./data/joplin:/data
EOF

# Start Joplin Server
msg_info "Starting Joplin Server"
$STD cd /opt/joplin
$STD docker-compose up -d
msg_ok "Started Joplin Server"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/joplin.service
[Unit]
Description=Joplin Server
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/joplin
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down

[Install]
WantedBy=multi-user.target
EOF
$STD systemctl enable joplin
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"