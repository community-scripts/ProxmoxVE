#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sysadminsmedia/homebox

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc
msg_ok "Installed Dependencies"

msg_info "Installing Homebox"
RELEASE=$(curl -s https://api.github.com/repos/sysadminsmedia/homebox/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -qO- https://github.com/sysadminsmedia/homebox/releases/download/${RELEASE}/homebox_Linux_x86_64.tar.gz | tar -xzf - -C /opt
chmod +x /opt/homebox
cat <<EOF >/opt/.env
# Application mode
# HBOX_MODE=production  # Can be one of: development, production

# Web server settings
HBOX_WEB_PORT=7745  # Port to run the web server on
HBOX_WEB_HOST=0.0.0.0  # Host to run the web server on (use 0.0.0.0 for all interfaces)

# File upload settings
HBOX_WEB_MAX_UPLOAD_SIZE=10  # Maximum file upload size supported in MB

# HTTP timeout settings
HBOX_WEB_READ_TIMEOUT=10  # Read timeout of HTTP server (seconds)
HBOX_WEB_WRITE_TIMEOUT=10  # Write timeout of HTTP server (seconds)
HBOX_WEB_IDLE_TIMEOUT=30  # Idle timeout of HTTP server (seconds)

# Storage settings
HBOX_STORAGE_DATA=/data/  # Path to the data directory
HBOX_STORAGE_SQLITE_URL=/data/homebox.db?_fk=1  # SQLite database URL

# Logging settings
HBOX_LOG_LEVEL=info  # Log level (trace, debug, info, warn, error, critical)
HBOX_LOG_FORMAT=text  # Log format (text or json)

# Mailer settings
# HBOX_MAILER_HOST=email-smtp.example.com  # Email host to use
# HBOX_MAILER_PORT=587  # Email port to use
# HBOX_MAILER_USERNAME=your_email@example.com  # Email user to use
# HBOX_MAILER_PASSWORD=your_password  # Email password to use
# HBOX_MAILER_FROM=your_email@example.com  # Email from address to use

# Swagger settings
HBOX_SWAGGER_HOST=localhost:7745  # Swagger host to use
HBOX_SWAGGER_SCHEME=http  # Swagger schema to use (http or https)

# Application options
HBOX_OPTIONS_ALLOW_REGISTRATION=true  # Allow users to register themselves
HBOX_OPTIONS_AUTO_INCREMENT_ASSET_ID=true  # Auto increment asset_id for new items

# Debug settings
# HBOX_DEBUG_ENABLED=false  # Enable or disable debugging
# HBOX_DEBUG_PORT=4000  # Debug port

# Demo settings
# HBOX_DEMO=true  # Enable demo mode (optional)
EOF
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Homebox"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/homebox.service
[Unit]
Description=Start Homebox Service
After=network.target

[Service]
WorkingDirectory=/opt
ExecStart=/opt/homebox
EnvironmentFile=/opt/.env
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now homebox.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
