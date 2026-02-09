#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: mikolaj92
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/janeczku/calibre-web

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# =============================================================================
# DEPENDENCIES - Calibre-Web requires Python and pip
# =============================================================================

msg_info "Installing Dependencies"
$STD apt install -y \
  python3 \
  python3-pip \
  imagemagick \
  libpango-1.0-0 \
  libharfbuzz0b \
  libpangoft2-1.0-0 \
  fonts-liberation
msg_ok "Installed Dependencies"

# =============================================================================
# OPTIONAL - Install Calibre for eBook conversion
# =============================================================================
msg_info "Installing Calibre (for eBook conversion)"
$STD apt install -y calibre
msg_ok "Installed Calibre"

# =============================================================================
# DOWNLOAD & DEPLOY APPLICATION
# =============================================================================

msg_info "Setting up Calibre-Web"
fetch_and_deploy_gh_release "calibre-web" "janeczku/calibre-web" "tarball" "latest" "/opt/calibre-web"
msg_ok "Setup Calibre-Web"

# =============================================================================
# INSTALL PYTHON DEPENDENCIES
# =============================================================================

msg_info "Installing Python Dependencies"
cd /opt/calibre-web
$STD pip3 install --no-cache-dir -r requirements.txt
msg_ok "Installed Python Dependencies"

# =============================================================================
# CREATE DATA DIRECTORY
# =============================================================================

msg_info "Creating Data Directory"
mkdir -p /opt/calibre-web/data
msg_ok "Created Data Directory"

# =============================================================================
# CREATE SYSTEMD SERVICE
# =============================================================================

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/cps.service
[Unit]
Description=Calibre-Web Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/calibre-web
ExecStart=/usr/bin/python3 /opt/calibre-web/cps.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cps
msg_ok "Created Service"

# =============================================================================
# CLEANUP & FINALIZATION
# =============================================================================
motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
