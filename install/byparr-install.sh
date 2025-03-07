#!/usr/bin/env bash

# Copyright (c) 2025
# License: MIT
# Source: https://github.com/ThePhaseless/Byparr

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y apt-transport-https
$STD apt-get install -y gpg
$STD apt-get install -y xvfb
$STD apt-get install -y scrot
$STD apt-get install -y xauth
$STD apt-get install -y ca-certificates
$STD apt-get install -y python3-pip
$STD apt-get install -y python3-venv
$STD apt-get install -y git
msg_ok "Installed Dependencies"

msg_info "Installing Chrome"
wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
$STD apt update
$STD apt install -y google-chrome-stable chromium chromium-driver
msg_ok "Installed Chrome"

msg_info "Installing UV Package Manager"
$STD curl -fsSL https://astral.sh/uv/install.sh | sh
msg_ok "Installed UV"

# Create Byparr directory
msg_info "Setting up Byparr"
mkdir -p /opt/byparr
cd /opt/byparr

# Clone Byparr repository
$STD git clone https://github.com/ThePhaseless/Byparr.git .

# Install Python dependencies with UV
msg_info "Installing Python dependencies"
export PATH="/root/.local/bin:$PATH"
$STD uv sync
# Fix for SeleniumBase arm64 if needed
if [ "$(uname -m)" = "aarch64" ]; then
  cd .venv/lib/*/site-packages/seleniumbase/drivers && ln -s /usr/bin/chromedriver uc_driver
  cd /opt/byparr
fi
msg_ok "Installed Python dependencies"

# Create cmd.sh execution script
msg_info "Creating execution script"
cat <<EOF >/opt/byparr/cmd.sh
#!/bin/bash
export DISPLAY=:0
export PYTHONUNBUFFERED=1
export PYTHONDONTWRITEBYTECODE=1

# Start Xvfb
Xvfb :0 -screen 0 1920x1080x24 &
xvfb_pid=\$!

# Start Byparr
cd /opt/byparr
export PATH="/root/.local/bin:\$PATH"
uv run python main.py

# Cleanup
kill \$xvfb_pid
EOF
chmod +x /opt/byparr/cmd.sh
msg_ok "Created execution script"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/byparr.service
[Unit]
Description=Byparr
After=network.target
[Service]
SyslogIdentifier=byparr
Restart=always
RestartSec=5
Type=simple
Environment="DISPLAY=:0"
Environment="PYTHONUNBUFFERED=1"
Environment="PYTHONDONTWRITEBYTECODE=1"
WorkingDirectory=/opt/byparr
ExecStart=/opt/byparr/cmd.sh
TimeoutStopSec=30
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now byparr.service
msg_ok "Created Service"

# Create update script
msg_info "Creating update script"
cat <<EOF >/opt/byparr/update.sh
#!/bin/bash
cd /opt/byparr
git pull
export PATH="/root/.local/bin:\$PATH"
uv sync
systemctl restart byparr.service
EOF
chmod +x /opt/byparr/update.sh
msg_ok "Created update script"

# Create test script
msg_info "Creating test script"
cat <<EOF >/opt/byparr/test.sh
#!/bin/bash
cd /opt/byparr
export PATH="/root/.local/bin:\$PATH"
export DISPLAY=:0

# Start Xvfb
Xvfb :0 -screen 0 1920x1080x24 &
xvfb_pid=\$!

# Run tests
uv sync --group test
uv run pytest --retries 3

# Cleanup
kill \$xvfb_pid
EOF
chmod +x /opt/byparr/test.sh
msg_ok "Created test script"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}Byparr setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8191${CL}"