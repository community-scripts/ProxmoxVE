#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://joplinapp.org/

APP="Joplin"
var_tags="${var_tags:-notes}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/joplin ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP} LXC"
  $STD apt-get update
  $STD apt-get -y upgrade
  
  # Update Joplin Server
  cd /opt/joplin
  $STD docker-compose pull
  $STD docker-compose up -d
  
  msg_ok "Updated ${APP} LXC"
  exit
}

start
build_container
description

msg_info "Setting up ${APP}"

# Install dependencies
msg_info "Installing dependencies"
$STD apt-get update
$STD apt-get install -y curl wget gnupg2 apt-transport-https ca-certificates software-properties-common

# Install Docker
msg_info "Installing Docker"
$STD curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
$STD echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
$STD apt-get update
$STD apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
$STD systemctl enable --now docker

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

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:22300${CL}"
echo -e "${INFO}${YW} Default admin credentials:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}Email: admin@localhost${CL}"
echo -e "${TAB}${GATEWAY}${BGN}Password: admin${CL}"
echo -e "${INFO}${YW} Please change the default password after first login!${CL}"