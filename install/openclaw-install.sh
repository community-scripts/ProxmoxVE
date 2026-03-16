#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
# Author: coe0718
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openclaw/openclaw

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
  ca-certificates \
  gnupg \
  whiptail
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
curl -fsSL https://deb.nodesource.com/setup_22.x | bash - &>/dev/null
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get install -y nodejs
msg_ok "Installed Node.js $(node -v)"

msg_info "Installing ${APP}"
$STD npm install -g openclaw@latest
msg_ok "Installed ${APP} $(npm list -g openclaw --depth=0 2>/dev/null | grep openclaw | awk -F'@' '{print $2}')"

msg_info "Creating ${APP} systemd service"
cat <<EOF >/etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw AI Assistant Gateway
Documentation=https://docs.openclaw.ai
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/bin/openclaw gateway start
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
# Service is enabled and started by the setup wizard on first SSH login
msg_ok "Created ${APP} systemd service"

msg_info "Installing setup wizard"
curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/install/openclaw-wizard.sh \
  -o /usr/local/bin/openclaw-wizard
chmod +x /usr/local/bin/openclaw-wizard
ln -sf /usr/local/bin/openclaw-wizard /usr/local/bin/openclaw-setup
msg_ok "Installed setup wizard at /usr/local/bin/openclaw-wizard"

msg_info "Configuring first-login trigger"
cat <<'EOF' >>/root/.bashrc

# OpenClaw first-run wizard
if [[ -z "$OPENCLAW_WIZARD_SKIP" ]] && [[ ! -f /root/.openclaw/.configured ]]; then
  /usr/local/bin/openclaw-wizard
fi
EOF
msg_ok "Wizard will run automatically on first SSH login"

motd_ssh
customize
