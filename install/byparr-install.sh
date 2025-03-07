#!/usr/bin/env bash

# Copyright (c) 2021-2025
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
curl -sSf https://astral.sh/uv/install.sh | bash
export PATH="/root/.local/bin:$PATH"
msg_ok "Installed UV"

msg_info "Cloning Byparr"
mkdir -p /opt/byparr
cd /opt/byparr
git clone https://github.com/ThePhaseless/Byparr.git .
msg_ok "Cloned Byparr"

msg_info "Installing Python Dependencies"
cd /opt/byparr
/root/.local/bin/uv sync
if [ "$(uname -m)" = "aarch64" ]; then
  cd .venv/lib/*/site-packages/seleniumbase/drivers && ln -s /usr/bin/chromedriver uc_driver
  cd /opt/byparr
fi
msg_ok "Installed Python Dependencies"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/byparr.service
[Unit]
Description=Byparr
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/byparr
Environment="PATH=/root/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="DISPLAY=:0"
Environment="PYTHONUNBUFFERED=1"
Environment="PYTHONDONTWRITEBYTECODE=1"
ExecStartPre=/usr/bin/Xvfb :0 -screen 0 1920x1080x24 -ac &
ExecStart=/opt/byparr/cmd.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now byparr.service
msg_ok "Created Service"

msg_info "Creating Test Script"
cat <<EOF >/opt/byparr/run-tests.sh
#!/bin/bash
cd /opt/byparr
export PATH="/root/.local/bin:\$PATH"
export DISPLAY=:0
export PYTHONUNBUFFERED=1
export PYTHONDONTWRITEBYTECODE=1

# Start Xvfb if not running
if ! pgrep Xvfb > /dev/null; then
  Xvfb :0 -screen 0 1920x1080x24 &
  xvfb_pid=\$!
  sleep 2
fi

# Run tests
/root/.local/bin/uv sync --group test
/root/.local/bin/uv run pytest --retries 3

test_result=\$?

# Kill Xvfb if we started it
if [ -n "\$xvfb_pid" ]; then
  kill \$xvfb_pid
fi

exit \$test_result
EOF
chmod +x /opt/byparr/run-tests.sh
msg_ok "Created Test Script"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"