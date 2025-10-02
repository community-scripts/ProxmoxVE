#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wez/govee2mqtt

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
  ca-certificates \
  docker.io
msg_ok "Installed Dependencies"

# Detect Architecture
msg_info "Detecting Architecture"
ARCH=$(dpkg --print-architecture)
case $ARCH in
  amd64)
    DOCKER_PLATFORM="linux/amd64"
    ;;
  arm64)
    DOCKER_PLATFORM="linux/arm64"
    ;;
  armhf)
    DOCKER_PLATFORM="linux/arm/v7"
    ;;
  *)
    msg_error "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac
msg_ok "Detected Architecture: $ARCH"

# Setup User
msg_info "Setting up Govee2MQTT User"
useradd -r -s /bin/false -d /opt/govee2mqtt -u 1000 govee2mqtt >/dev/null 2>&1
mkdir -p /opt/govee2mqtt/{assets,target/release}
mkdir -p /data/govee2mqtt
chown govee2mqtt:govee2mqtt /data/govee2mqtt /opt/govee2mqtt
msg_ok "Created Govee2MQTT User"

msg_info "Installing Govee2MQTT"
systemctl start docker

# Extract binary from official Docker image
TEMP_CONTAINER=$(docker create --platform=$DOCKER_PLATFORM ghcr.io/wez/govee2mqtt:latest)
docker cp "$TEMP_CONTAINER:/app/govee" /opt/govee2mqtt/target/release/govee
docker cp "$TEMP_CONTAINER:/app/assets" /opt/govee2mqtt/ 2>/dev/null || true
docker cp "$TEMP_CONTAINER:/app/AmazonRootCA1.pem" /opt/govee2mqtt/ 2>/dev/null || true
docker rm "$TEMP_CONTAINER"

# Fallback for missing assets from source
if [ ! -d "/opt/govee2mqtt/assets" ] || [ ! -f "/opt/govee2mqtt/AmazonRootCA1.pem" ]; then
  RELEASE=$(curl -fsSL https://api.github.com/repos/wez/govee2mqtt/tags | grep '"name"' | head -1 | cut -d'"' -f4)
  curl -fsSL -o "govee2mqtt-${RELEASE}.tar.gz" "https://github.com/wez/govee2mqtt/archive/refs/tags/${RELEASE}.tar.gz"
  tar -xzf "govee2mqtt-${RELEASE}.tar.gz"
  [ ! -d "/opt/govee2mqtt/assets" ] && cp -r "govee2mqtt-${RELEASE#v}/assets" /opt/govee2mqtt/
  [ ! -f "/opt/govee2mqtt/AmazonRootCA1.pem" ] && cp "govee2mqtt-${RELEASE#v}/AmazonRootCA1.pem" /opt/govee2mqtt/
  rm -rf "govee2mqtt-${RELEASE#v}" "govee2mqtt-${RELEASE}.tar.gz"
fi

chmod +x /opt/govee2mqtt/target/release/govee
chown -R govee2mqtt:govee2mqtt /opt/govee2mqtt
msg_ok "Installed Govee2MQTT"

# Creating Service
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/govee2mqtt.service
[Unit]
Description=Govee to MQTT Bridge
After=network.target
Wants=network.target

[Service]
Type=simple
User=govee2mqtt
Group=govee2mqtt
WorkingDirectory=/opt/govee2mqtt
EnvironmentFile=-/opt/govee2mqtt/.env
Environment=RUST_BACKTRACE=full
Environment=XDG_CACHE_HOME=/data/govee2mqtt
ExecStart=/opt/govee2mqtt/target/release/govee serve --govee-iot-key=/data/govee2mqtt/iot.key --govee-iot-cert=/data/govee2mqtt/iot.cert --amazon-root-ca=/opt/govee2mqtt/AmazonRootCA1.pem
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/govee2mqtt /data/govee2mqtt
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
EOF

# Create configuration template
cat <<EOF >/opt/govee2mqtt/.env.example
# Govee Account Credentials (recommended)
GOVEE_EMAIL=your.email@example.com
GOVEE_PASSWORD=your_govee_password

# Govee API Key (optional but recommended for full functionality)  
# Get your API key from: https://developer.govee.com/reference/apply-you-govee-api-key
GOVEE_API_KEY=your_api_key_here

# MQTT Broker Configuration (required)
GOVEE_MQTT_HOST=192.168.1.100
GOVEE_MQTT_PORT=1883
# GOVEE_MQTT_USER=mqtt_username
# GOVEE_MQTT_PASSWORD=mqtt_password

# Temperature Scale (F or C)
GOVEE_TEMPERATURE_SCALE=F

# Timezone
TZ=America/New_York

# LAN Discovery Options (helps find devices on your network)
GOVEE_LAN_BROADCAST_ALL=true
GOVEE_LAN_BROADCAST_GLOBAL=true

# Logging
RUST_LOG_STYLE=always
# RUST_LOG=govee=debug  # Uncomment for debug logging

# Runtime Environment
RUST_BACKTRACE=full
XDG_CACHE_HOME=/data/govee2mqtt
EOF

chown govee2mqtt:govee2mqtt /opt/govee2mqtt/.env.example

# Create IoT certificate documentation
cat <<EOF >/data/govee2mqtt/README-certificates.txt
IoT Certificate Files
====================

This directory should contain your Govee IoT certificates:
- iot.key  : Your private IoT key file  
- iot.cert : Your IoT certificate file

These files are automatically generated when you first run govee2mqtt.
The service will create them during initial authentication.

To configure and start:
1. Copy configuration: cp /opt/govee2mqtt/.env.example /opt/govee2mqtt/.env
2. Edit with your credentials: nano /opt/govee2mqtt/.env  
3. Start service: systemctl start govee2mqtt
4. Check status: systemctl status govee2mqtt
5. View logs: journalctl -fu govee2mqtt
EOF

chown govee2mqtt:govee2mqtt /data/govee2mqtt/README-certificates.txt

{
  echo "Govee2MQTT Configuration"
  echo "Configuration file: /opt/govee2mqtt/.env"
  echo "Data directory: /data/govee2mqtt"
  echo "Service: govee2mqtt.service"
  echo ""
  echo "Next steps:"
  echo "1. cp /opt/govee2mqtt/.env.example /opt/govee2mqtt/.env"
  echo "2. nano /opt/govee2mqtt/.env"
  echo "3. systemctl start govee2mqtt"
} >>~/govee2mqtt.creds

systemctl enable -q govee2mqtt
msg_ok "Created Service"

motd_ssh
customize

motd_ssh
customize

msg_info "Cleaning up"
systemctl stop docker
$STD apt-get remove -y docker.io
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"