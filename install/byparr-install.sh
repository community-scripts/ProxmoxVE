#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tanujdargan
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ThePhaseless/Byparr

set -e #terminate script if it fails a command

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

LOG_FILE="/var/log/byparr-install.log"
$STD echo "Starting Byparr installation at $(date)" > "$LOG_FILE"

# Set root password to 'root' - more robust approach
msg_info "Setting default root password"
# Try multiple methods to ensure the password gets set
$STD passwd --delete root  # First delete any existing password
$STD echo -e "root\nroot" | passwd root
$STD echo "root:root" | chpasswd
# Verify the password was set
if ! $STD grep -q "root:" /etc/shadow; then
  msg_error "Failed to find root entry in /etc/shadow"
  exit 1
fi
msg_ok "Root password has been set to 'root'"

# Set up auto-login for root on console
msg_info "Setting up auto-login for console"
$STD mkdir -p /etc/systemd/system/getty@tty1.service.d/
$STD cat <<EOF >/etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOF
$STD systemctl daemon-reload
msg_ok "Set up auto-login for console"

# Installing Dependencies
msg_info "Installing Dependencies"
$STD apt-get update
$STD apt-get install -y curl sudo mc apt-transport-https gpg xvfb git
msg_ok "Installed Dependencies"

# Installing Chrome
msg_info "Installing Chrome"
$STD wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
$STD echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
$STD apt-get update
$STD apt-get install -y google-chrome-stable
msg_ok "Installed Chrome"

# Installing UV Package Manager
msg_info "Installing UV Package Manager" 
$STD curl -LsSf https://astral.sh/uv/install.sh | sh
# Make sure we source the env file properly
$STD echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
$STD echo 'source "$HOME/.local/bin/env"' >> ~/.bashrc
$STD source $HOME/.local/bin/env
msg_ok "Installed UV Package Manager"

# Installing Byparr
msg_info "Installing Byparr"
$STD git clone https://github.com/ThePhaseless/Byparr.git /opt/byparr
$STD cd /opt/byparr
# Source env again to ensure uv command is available
$STD source $HOME/.local/bin/env
$STD uv sync --group test
msg_ok "Installed Byparr"

# Creating wrapper script
msg_info "Creating startup wrapper script"
$STD cat <<EOF >/opt/byparr/start-byparr.sh
#!/bin/bash

# Source the environment file to set up PATH
if [ -f /root/.local/bin/env ]; then
  source /root/.local/bin/env
fi

# Change to the Byparr directory
cd /opt/byparr

# Run UV sync and start the application
uv sync && ./cmd.sh
EOF

# Make the wrapper script executable
$STD chmod +x /opt/byparr/start-byparr.sh
msg_ok "Created startup wrapper script"

# Creating Service
msg_info "Creating Service"
$STD cat <<EOF >/etc/systemd/system/byparr.service
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
ExecStart=/opt/byparr/start-byparr.sh
TimeoutStopSec=60
[Install]
WantedBy=multi-user.target
EOF
$STD systemctl daemon-reload
$STD systemctl enable --now byparr.service
msg_ok "Created Service"

# Fix SSH access - enhanced version
msg_info "Setting up system access"
# Enable root login via SSH
$STD sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
# Make sure password authentication is enabled
$STD sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
$STD sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# Make sure PAM is enabled
$STD sed -i 's/#UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config
# Restart SSH service
$STD systemctl restart sshd
# Verify root login is enabled
if ! $STD grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
  msg_error "Failed to enable root login in SSH config"
  # Try a more direct approach if the sed command failed
  $STD echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
  $STD echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
  $STD systemctl restart sshd
fi
msg_ok "System access configured"

motd_ssh
customize

# Double-check password is still set correctly
msg_info "Verifying password configuration"
$STD echo "root:root" | chpasswd
msg_ok "Password verified"

# Cleanup
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

$STD echo "Byparr installation completed successfully at $(date)" >> "$LOG_FILE"

# Print login information - this should always show
echo ""
echo "======== LOGIN INFORMATION ========"
echo "Username: root"
echo "Password: root"
echo "=================================="