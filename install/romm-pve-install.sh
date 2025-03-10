#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: DevelopmentCats
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://git.chesher.xyz/cat/romm-proxmox-ve-script

# Define color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function msg_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

function msg_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

function msg_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Container settings
CONTAINER_NAME="romm"
CONTAINER_DESCRIPTION="RomM - ROM Manager"
CONTAINER_MEMORY="2048"
CONTAINER_CORES="2"
CONTAINER_DISK_SIZE="20G"
CONTAINER_FEATURES="nesting=1"
CONTAINER_OS_TYPE="debian"
CONTAINER_OS_VERSION="12"
CONTAINER_ARCH="amd64"
APPLICATION="romm"

# Check if script is running on Proxmox
if [ ! -d "/etc/pve" ]; then
  msg_error "This script must be run on a Proxmox VE host"
  exit 1
fi

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
  msg_error "This script must be run as root"
  exit 1
fi

# Show banner
echo -e "\n${YELLOW}=== RomM Proxmox VE Installation Script ===${NC}\n"

# Get user input for container configuration
msg_info "Creating ${APPLICATION} LXC Container"
read -p "Enter CT ID (leave empty for automatic assignment): " CT_ID
if [ -z "$CT_ID" ]; then
  msg_info "Finding highest CT ID and incrementing..."
  # Get the highest CT ID currently in use
  HIGHEST_ID=$(pct list | tail -n +2 | awk '{print $1}' | sort -n | tail -1)
  # If no containers exist, start with 100, otherwise increment the highest ID
  if [ -z "$HIGHEST_ID" ]; then
    NEXT_ID=100
  else
    NEXT_ID=$((HIGHEST_ID + 1))
  fi
  CT_ID=$NEXT_ID
  msg_info "Using CT ID: $CT_ID"
fi

read -p "Enter CT hostname (${CONTAINER_NAME}): " CT_HOSTNAME
CT_HOSTNAME=${CT_HOSTNAME:-${CONTAINER_NAME}}
read -p "Enter disk size (${CONTAINER_DISK_SIZE}): " CT_DISK_SIZE
CT_DISK_SIZE=${CT_DISK_SIZE:-${CONTAINER_DISK_SIZE}}

# Remove the 'G' suffix from disk size for proper formatting
CT_DISK_SIZE_CLEAN=$(echo "${CT_DISK_SIZE}" | sed 's/G$//')

read -p "Enter memory size in MB (${CONTAINER_MEMORY}): " CT_MEMORY
CT_MEMORY=${CT_MEMORY:-${CONTAINER_MEMORY}}
read -p "Enter number of CPU cores (${CONTAINER_CORES}): " CT_CORES
CT_CORES=${CT_CORES:-${CONTAINER_CORES}}

# Make password prompt more visible
echo
echo -e "${YELLOW}---------------------------------------------${NC}"
echo -e "${YELLOW}|       LXC CONTAINER PASSWORD SETUP        |${NC}"
echo -e "${YELLOW}---------------------------------------------${NC}"
echo -e "${RED}IMPORTANT:${NC} This password will be used for the root user in the container."
echo -e "           A secure password is recommended for production environments."

# Password input with retry logic
PASSWORD_CONFIRMED=false
while [ "$PASSWORD_CONFIRMED" != "true" ]; do
    read -s -p "Enter root password for the container (or press Enter for default 'changeme'): " CT_PASSWORD
    echo
    
    # If user entered a password, confirm it
    if [ ! -z "$CT_PASSWORD" ]; then
        read -s -p "Confirm root password: " CT_PASSWORD_CONFIRM
        echo
        
        if [ "$CT_PASSWORD" == "$CT_PASSWORD_CONFIRM" ]; then
            PASSWORD_CONFIRMED=true
            msg_ok "Password confirmed"
        else
            msg_error "Passwords do not match! Please try again."
            # Let the loop continue to ask for password again
        fi
    else
        # User pressed Enter without typing password
        CT_PASSWORD="changeme"
        echo -e "${YELLOW}Using default password: 'changeme' - Please change this after installation!${NC}"
        PASSWORD_CONFIRMED=true
    fi
done

echo -e "${YELLOW}----------------------------------------${NC}"
echo

# Get network configuration
default_bridge="vmbr0"
read -p "Enter network bridge (${default_bridge}): " CT_BRIDGE
CT_BRIDGE=${CT_BRIDGE:-${default_bridge}}

# For IP configuration, default to DHCP if user provides no input
msg_info "Network Configuration"
echo "For IP address, you can:"
echo "- Leave blank to use DHCP"
echo "- Enter an IPv4 address in CIDR format (e.g., 192.168.1.100/24)"
read -p "IP Address (DHCP): " CT_IP

# If IP is empty, set it to dhcp
if [ -z "$CT_IP" ]; then
  msg_info "Using DHCP for IP assignment"
  CT_IP="dhcp"
else
  # Validate IP address format (simple check)
  if [[ ! $CT_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
    msg_error "Invalid IP address format. Using DHCP instead."
    CT_IP="dhcp"
  fi
fi

# Get storage information
msg_info "Storage Configuration"

# Display available storages with their free space
echo "Available storages:"
echo "-----------------------------------------"
echo "NAME         TYPE        AVAILABLE SPACE"
echo "-----------------------------------------"
pvesm status -content rootdir,images | grep -v "enabled" | grep -v "Name" | while read line; do
  # Extract storage name, type and available space
  NAME=$(echo $line | awk '{print $1}')
  TYPE=$(echo $line | awk '{print $2}')
  AVAIL=$(echo $line | awk '{print $4$5}')
  
  # Print formatted output
  printf "%-12s %-11s %-15s\n" "$NAME" "$TYPE" "$AVAIL"
done
echo "-----------------------------------------"

# Ask for storage
default_storage="local-lvm"
read -p "Storage for container (${default_storage}): " CT_STORAGE
CT_STORAGE=${CT_STORAGE:-${default_storage}}

# Verify storage exists
if ! pvesm status | grep -q "^$CT_STORAGE "; then
  msg_error "Storage $CT_STORAGE does not exist! Using default: $default_storage"
  CT_STORAGE=$default_storage
fi

# Find the most recent Debian 12 standard template
msg_info "Looking for Debian 12 template..."
TEMPLATE=$(pvesm list local | grep -o "local:vztmpl/debian-12-standard.*_amd64.tar.[xz|zst]*" | sort -V | tail -n1)

if [ -z "$TEMPLATE" ]; then
  msg_error "No Debian 12 template found. Please download it first."
  echo "You can download it using: pveam download local debian-12-standard_12.7-1_amd64.tar.zst"
  exit 1
fi

msg_info "Using template: $TEMPLATE"

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

# Create the container
msg_info "Creating ${APPLICATION} LXC container (ID: ${CT_ID})"
pct create ${CT_ID} ${TEMPLATE} \
  --hostname ${CT_HOSTNAME} \
  --cores ${CT_CORES} \
  --memory ${CT_MEMORY} \
  --swap 0 \
  --rootfs ${CT_STORAGE}:${CT_DISK_SIZE_CLEAN} \
  --ostype ${CONTAINER_OS_TYPE} \
  --net0 name=eth0,bridge=${CT_BRIDGE},ip=${CT_IP} \
  --onboot 1 \
  --password "${CT_PASSWORD}" \
  --unprivileged 1 \
  --features ${CONTAINER_FEATURES}

# Set container description
pct set ${CT_ID} -description "${CONTAINER_DESCRIPTION}"

# Start the container
msg_info "Starting LXC container..."
pct start ${CT_ID}
sleep 5

# Run installation commands in the container
msg_info "Installing ${APPLICATION} inside the container..."

# Define the installation script to be executed inside the container
cat > /tmp/romm_install.sh <<'EOL'
#!/bin/bash
# Update sources
apt-get update
apt-get upgrade -y

# Install dependencies
apt-get install -y \
  sudo \
  curl \
  openssl \
  ca-certificates \
  gnupg \
  mc \
  wget

# Install Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create directories with recommended folder structure
mkdir -p /opt/romm/library/{roms,bios}
# Create example platform folders in roms directory
mkdir -p /opt/romm/library/roms/{gbc,gba,ps}
# Create example platform folders in bios directory
mkdir -p /opt/romm/library/bios/{gba,ps}
mkdir -p /opt/romm/assets
mkdir -p /opt/romm/config

# Generate authentication key
AUTH_KEY=$(openssl rand -hex 32)

# Generate secure passwords
DB_ROOT_PASSWORD=$(openssl rand -hex 16)
DB_USER_PASSWORD=$(openssl rand -hex 16)

# Background task settings from host
BG_ENABLE_RESCAN_FS_CHANGE="${BG_ENABLE_RESCAN_FS_CHANGE}"
BG_RESCAN_FS_CHANGE_DELAY="${BG_RESCAN_FS_CHANGE_DELAY}"
BG_ENABLE_SCHEDULED_RESCAN="${BG_ENABLE_SCHEDULED_RESCAN}"
BG_SCHEDULED_RESCAN_CRON="${BG_SCHEDULED_RESCAN_CRON}"
BG_ENABLE_UPDATE_SWITCH_TITLEDB="${BG_ENABLE_UPDATE_SWITCH_TITLEDB}"
BG_UPDATE_SWITCH_TITLEDB_CRON="${BG_UPDATE_SWITCH_TITLEDB_CRON}"

# Create docker-compose.yml
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
      - ENABLE_RESCAN_ON_FILESYSTEM_CHANGE=${BG_ENABLE_RESCAN_FS_CHANGE:-false}
      - RESCAN_ON_FILESYSTEM_CHANGE_DELAY=${BG_RESCAN_FS_CHANGE_DELAY:-5}
      - ENABLE_SCHEDULED_RESCAN=${BG_ENABLE_SCHEDULED_RESCAN:-false}
      - SCHEDULED_RESCAN_CRON="${BG_SCHEDULED_RESCAN_CRON:-0 3 * * *}"
      - ENABLE_SCHEDULED_UPDATE_SWITCH_TITLEDB=${BG_ENABLE_UPDATE_SWITCH_TITLEDB:-false}
      - SCHEDULED_UPDATE_SWITCH_TITLEDB_CRON="${BG_UPDATE_SWITCH_TITLEDB_CRON:-0 4 * * *}"
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

# Start the containers
cd /opt/romm
docker compose up -d

# Configure firewall if it exists
if command -v ufw >/dev/null 2>&1; then
  ufw allow 8080/tcp
fi

# Output IP address for access
IP=$(hostname -I | awk '{print $1}')
echo "RomM has been installed and is running on http://${IP}:8080"
EOL

# Make script executable and execute it in the container
chmod +x /tmp/romm_install.sh
pct push ${CT_ID} /tmp/romm_install.sh /tmp/romm_install.sh 
pct exec ${CT_ID} -- bash /tmp/romm_install.sh

# Get container IP
CONTAINER_IP=$(pct exec ${CT_ID} -- hostname -I | tr -d '\n')

# Clean up
rm /tmp/romm_install.sh

# Display final message
msg_ok "RomM Installation Complete"
echo "========================================================================"
echo "RomM has been installed in LXC container ${CT_ID}"
echo "Access the RomM web interface at http://${CONTAINER_IP}:8080"
echo
echo "API keys and background tasks can be configured through the web interface"
echo "or by editing /opt/romm/docker-compose.yml within the container."
echo
echo "Folder structure has been created with example platform folders:"
echo "- ROM folders: gbc, gba, ps"
echo "- BIOS folders: gba, ps"
echo
echo "Place your ROMs in: /opt/romm/library/roms/PLATFORM_NAME/"
echo "Place your BIOS files in: /opt/romm/library/bios/PLATFORM_NAME/"
echo
echo "On first visit to the web interface, you'll need to complete the setup"
echo "wizard and create an admin account."
echo "========================================================================" 
