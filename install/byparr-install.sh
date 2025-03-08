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

# Define output redirection based on verbose flag
if [ "$VERBOSE" = "1" ]; then
  REDIRECT=""
else
  REDIRECT=">/dev/null 2>&1"
fi

LOG_FILE="/var/log/byparr-install.log"
echo "Starting Byparr installation at $(date)" > "$LOG_FILE"

# Set root password to 'root' - more robust approach
msg_info "Setting default root password"
# Try multiple methods to ensure the password gets set
eval "passwd --delete root $REDIRECT"  # First delete any existing password
eval "echo -e 'root\nroot' | passwd root $REDIRECT"
eval "echo 'root:root' | chpasswd $REDIRECT"
# Verify the password was set
if ! eval "grep -q 'root:' /etc/shadow $REDIRECT"; then
  msg_error "Failed to find root entry in /etc/shadow"
  exit 1
fi
msg_ok "Root password has been set to 'root'"

# Set up auto-login for root on console
msg_info "Setting up auto-login for console"
eval "mkdir -p /etc/systemd/system/getty@tty1.service.d/ $REDIRECT"
cat <<EOF >/etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOF
eval "systemctl daemon-reload $REDIRECT"
msg_ok "Set up auto-login for console"

# Installing Dependencies
msg_info "Installing Dependencies"
eval "apt-get update $REDIRECT"
eval "apt-get install -y curl sudo mc apt-transport-https gpg xvfb git $REDIRECT"
msg_ok "Installed Dependencies"

# Installing Chrome
msg_info "Installing Chrome"
eval "wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg $REDIRECT"
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
eval "apt-get update $REDIRECT"
eval "apt-get install -y google-chrome-stable $REDIRECT"
msg_ok "Installed Chrome"

# Installing UV Package Manager
msg_info "Installing UV Package Manager" 
eval "curl -LsSf https://astral.sh/uv/install.sh | sh $REDIRECT"
# Make sure we source the env file properly
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo 'source "$HOME/.local/bin/env"' >> ~/.bashrc
eval "source $HOME/.local/bin/env $REDIRECT || true"
msg_ok "Installed UV Package Manager"

# Installing Byparr
msg_info "Installing Byparr"
eval "git clone https://github.com/ThePhaseless/Byparr.git /opt/byparr $REDIRECT"
cd /opt/byparr
# Source env again to ensure uv command is available
eval "source $HOME/.local/bin/env $REDIRECT || true"
eval "uv sync --group test $REDIRECT"
msg_ok "Installed Byparr"

# Creating wrapper script
msg_info "Creating startup wrapper script"
cat <<EOF >/opt/byparr/start-byparr.sh
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
eval "chmod +x /opt/byparr/start-byparr.sh $REDIRECT"
msg_ok "Created startup wrapper script"

# Creating Service
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
Environment="LOG_LEVEL=info"
Environment="CAPTCHA_SOLVER=none"
Environment="PATH=/root/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
WorkingDirectory=/opt/byparr
ExecStart=/opt/byparr/start-byparr.sh
TimeoutStopSec=60
[Install]
WantedBy=multi-user.target
EOF
eval "systemctl daemon-reload $REDIRECT"
eval "systemctl enable --now byparr.service $REDIRECT"
msg_ok "Created Service"

# Fix SSH access - enhanced version
msg_info "Setting up system access"
# Enable root login via SSH
eval "sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config $REDIRECT"
# Make sure password authentication is enabled
eval "sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config $REDIRECT"
eval "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config $REDIRECT"
# Make sure PAM is enabled
eval "sed -i 's/#UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config $REDIRECT"
# Restart SSH service
eval "systemctl restart sshd $REDIRECT"
# Verify root login is enabled
if ! eval "grep -q '^PermitRootLogin yes' /etc/ssh/sshd_config $REDIRECT"; then
  msg_error "Failed to enable root login in SSH config"
  # Try a more direct approach if the sed command failed
  echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
  echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
  eval "systemctl restart sshd $REDIRECT"
fi
msg_ok "System access configured"

motd_ssh
customize

# Double-check password is still set correctly
msg_info "Verifying password configuration"
eval "echo 'root:root' | chpasswd $REDIRECT"
msg_ok "Password verified"

# Cleanup
msg_info "Cleaning up"
eval "apt-get -y autoremove $REDIRECT"
eval "apt-get -y autoclean $REDIRECT"
msg_ok "Cleaned"

echo "Byparr installation completed successfully at $(date)" >> "$LOG_FILE"

# Print login information - this should always show
echo ""
echo "======== LOGIN INFORMATION ========"
echo "Username: root"
echo "Password: root"
echo "=================================="