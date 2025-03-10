#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: DevelopmentCats
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://git.chesher.xyz/cat/romm-proxmox-ve-script

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y sudo curl openssl ca-certificates gnupg mc wget
msg_ok "Installed Dependencies"

msg_info "Installing Docker"
$STD install -m 0755 -d /etc/apt/keyrings

# Download the key to a temporary file first - this prevents pipe failures
KEY_TMP_FILE=$(mktemp)
$STD curl -fsSL https://download.docker.com/linux/debian/gpg -o $KEY_TMP_FILE

# Check if the key was downloaded successfully
if [ -s "$KEY_TMP_FILE" ]; then
  # Process the key file
  $STD cat $KEY_TMP_FILE | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  $STD chmod a+r /etc/apt/keyrings/docker.gpg
  rm -f $KEY_TMP_FILE
else
  echo "Failed to download Docker GPG key. Trying alternate method..."
  # Alternative approach using apt-key (deprecated but works in many cases)
  $STD curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
  # Create docker.list without signed-by option
  echo \
    "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  rm -f $KEY_TMP_FILE
  
  # Continue with installation
  $STD apt-get update
  $STD apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  msg_ok "Installed Docker (alternative method)"
  return
fi

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

$STD apt-get update
$STD apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
msg_ok "Installed Docker"

msg_info "Creating Directories"
mkdir -p /opt/romm/library/{roms,bios}
mkdir -p /opt/romm/library/roms/{gbc,gba,ps}
mkdir -p /opt/romm/library/bios/{gba,ps}
mkdir -p /opt/romm/assets
mkdir -p /opt/romm/config
msg_ok "Created Directories"

msg_info "Generating Credentials"
AUTH_KEY=$(openssl rand -hex 32)
DB_ROOT_PASSWORD=$(openssl rand -hex 16)
DB_USER_PASSWORD=$(openssl rand -hex 16)
msg_ok "Generated Credentials"

# Ask if the user wants to configure background tasks
msg_info "Background Tasks Configuration"
echo "RomM supports automatic background tasks for library maintenance."
read -p "Do you want to configure background tasks? (y/n): " CONFIGURE_BACKGROUND_TASKS

# Initialize background task variables with defaults
BG_ENABLE_RESCAN_FS_CHANGE="false"
BG_RESCAN_FS_CHANGE_DELAY="5"
BG_ENABLE_SCHEDULED_RESCAN="false"
BG_SCHEDULED_RESCAN_CRON="0 3 * * *"
BG_ENABLE_UPDATE_SWITCH_TITLEDB="false"
BG_UPDATE_SWITCH_TITLEDB_CRON="0 4 * * *"

if [[ "${CONFIGURE_BACKGROUND_TASKS}" =~ ^[Yy]$ ]]; then
    msg_info "Configuring Background Tasks"
    echo "For each setting, press Enter to use the default value."
    
    # Configure auto-rescan on filesystem changes
    read -p "Enable auto-rescan when files change? (default: false): " temp_input
    if [ ! -z "$temp_input" ]; then BG_ENABLE_RESCAN_FS_CHANGE="$temp_input"; fi
    
    # If auto-rescan is enabled, ask for delay
    if [[ "${BG_ENABLE_RESCAN_FS_CHANGE}" =~ ^[Tt][Rr][Uu][Ee]$ ]]; then
        read -p "Delay before rescan after file changes (in minutes, default: 5): " temp_input
        if [ ! -z "$temp_input" ]; then BG_RESCAN_FS_CHANGE_DELAY="$temp_input"; fi
    fi
    
    # Configure scheduled rescan
    read -p "Enable scheduled library rescans? (default: false): " temp_input
    if [ ! -z "$temp_input" ]; then BG_ENABLE_SCHEDULED_RESCAN="$temp_input"; fi
    
    # If scheduled rescan is enabled, ask for cron schedule
    if [[ "${BG_ENABLE_SCHEDULED_RESCAN}" =~ ^[Tt][Rr][Uu][Ee]$ ]]; then
        read -p "Cron schedule for rescans (default: 0 3 * * * = 3 AM daily): " temp_input
        if [ ! -z "$temp_input" ]; then BG_SCHEDULED_RESCAN_CRON="$temp_input"; fi
    fi
    
    # Configure Switch TitleDB update
    read -p "Enable scheduled Switch TitleDB updates? (default: false): " temp_input
    if [ ! -z "$temp_input" ]; then BG_ENABLE_UPDATE_SWITCH_TITLEDB="$temp_input"; fi
    
    # If Switch TitleDB update is enabled, ask for cron schedule
    if [[ "${BG_ENABLE_UPDATE_SWITCH_TITLEDB}" =~ ^[Tt][Rr][Uu][Ee]$ ]]; then
        read -p "Cron schedule for TitleDB updates (default: 0 4 * * * = 4 AM daily): " temp_input
        if [ ! -z "$temp_input" ]; then BG_UPDATE_SWITCH_TITLEDB_CRON="$temp_input"; fi
    fi
    
    msg_ok "Background tasks configured"
else
    msg_info "Using default background task settings (all disabled)"
fi

msg_info "Creating Docker Compose File"
cat >/opt/romm/docker-compose.yml <<EOF
version: "3"
volumes:
  mysql_data:
  romm_resources:
  romm_redis_data:
services:
  romm:
    image: rommapp/romm:latest
    container_name: romm
    restart: unless-stopped
    environment:
      - DB_HOST=romm-db
      - DB_NAME=romm
      - DB_USER=romm-user
      - DB_PASSWD=${DB_USER_PASSWORD}
      - ROMM_AUTH_SECRET_KEY=${AUTH_KEY}
      # Background task settings
      - ENABLE_RESCAN_ON_FILESYSTEM_CHANGE=${BG_ENABLE_RESCAN_FS_CHANGE}
      - RESCAN_ON_FILESYSTEM_CHANGE_DELAY=${BG_RESCAN_FS_CHANGE_DELAY}
      - ENABLE_SCHEDULED_RESCAN=${BG_ENABLE_SCHEDULED_RESCAN}
      - SCHEDULED_RESCAN_CRON="${BG_SCHEDULED_RESCAN_CRON}"
      - ENABLE_SCHEDULED_UPDATE_SWITCH_TITLEDB=${BG_ENABLE_UPDATE_SWITCH_TITLEDB}
      - SCHEDULED_UPDATE_SWITCH_TITLEDB_CRON="${BG_UPDATE_SWITCH_TITLEDB_CRON}"
    volumes:
      - romm_resources:/romm/resources
      - romm_redis_data:/redis-data
      - /opt/romm/library:/romm/library
      - /opt/romm/assets:/romm/assets
      - /opt/romm/config:/romm/config
    ports:
      - 8080:8080
    depends_on:
      romm-db:
        condition: service_healthy
        restart: true
  romm-db:
    image: mariadb:latest
    container_name: romm-db
    restart: unless-stopped
    environment:
      - MARIADB_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      - MARIADB_DATABASE=romm
      - MARIADB_USER=romm-user
      - MARIADB_PASSWORD=${DB_USER_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      start_period: 30s
      start_interval: 10s
      interval: 10s
      timeout: 5s
      retries: 5
EOF
msg_ok "Created Docker Compose File"

msg_info "Starting RomM"
cd /opt/romm
$STD docker compose up -d
msg_ok "Started RomM"

# Configure firewall if it exists
if command -v ufw >/dev/null 2>&1; then
  msg_info "Configuring Firewall"
  $STD ufw allow 8080/tcp
  msg_ok "Configured Firewall"
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned" 
