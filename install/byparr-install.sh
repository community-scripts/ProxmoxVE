#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# Co-Author: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ThePhaseless/Byparr

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

LOG_FILE="/var/log/byparr-install.log"

# Function to log messages
log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "$1" | tee -a "$LOG_FILE"
    else
        echo "$1"
    fi
}

# Check for verbose option
VERBOSE=false
for arg in "$@"; do
    if [[ "$arg" == "--verbose" ]]; then
        VERBOSE=true
        log "Verbose mode enabled."
    fi
done

log "Installing Dependencies"
$STD apt-get install -y curl sudo mc apt-transport-https gpg xvfb git | tee -a "$LOG_FILE"
log "Installed Dependencies"

log "Installing Chrome"
wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
$STD apt update | tee -a "$LOG_FILE"
$STD apt install -y google-chrome-stable | tee -a "$LOG_FILE"
log "Installed Chrome"

log "Installing UV Package Manager"
$STD curl -LsSf https://astral.sh/uv/install.sh | sh | tee -a "$LOG_FILE"
source $HOME/.local/bin/env
log "Installed UV Package Manager"

log "Installing Byparr"
mkdir /home/byparr
$STD git clone https://github.com/ThePhaseless/Byparr.git /opt/byparr | tee -a "$LOG_FILE"
cd /home/byparr
$STD uv sync --group test | tee -a "$LOG_FILE"
$STD uv run pytest --retries 3 | tee -a "$LOG_FILE"
log "Installed Byparr"

log "Creating Service"
cat <<EOF >/etc/systemd/system/byparr.service
[Unit]
Description=Byparr
After=network.target
[Service]
SyslogIdentifier=byparr
Restart=always
RestartSec=5
Type=simple
Environment="LOG_LEVEL=info"
Environment="CAPTCHA_SOLVER=none"
WorkingDirectory=/opt/byparr
ExecStart=/bin/bash -c "uv sync && ./cmd.sh"
TimeoutStopSec=60
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now byparr.service | tee -a "$LOG_FILE"
log "Created Service"

motd_ssh
customize

log "Cleaning up"
$STD apt-get -y autoremove | tee -a "$LOG_FILE"
$STD apt-get -y autoclean | tee -a "$LOG_FILE"
log "Cleaned"