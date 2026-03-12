#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: glabutis
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/bitfocus/companion

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  libusb-1.0-0
msg_ok "Installed Dependencies"

msg_info "Fetching Latest Bitfocus Companion Release"
RELEASE_JSON=$(curl -fsSL "https://api.bitfocus.io/v1/product/companion/packages?limit=20")
RELEASE=$(echo "$RELEASE_JSON" | grep -o '"version":"[^"]*","target":"linux-tgz"' | head -1 | awk -F'"' '{print $4}')
ASSET_URL=$(echo "$RELEASE_JSON" | grep -o '"uri":"[^"]*linux-x64[^"]*"' | head -1 | awk -F'"' '{print $4}')

if [[ -z "$ASSET_URL" ]]; then
  msg_error "Could not locate a Linux x64 release from the Bitfocus API."
  exit 1
fi
msg_ok "Found ${APP} ${RELEASE}"

msg_info "Downloading Bitfocus Companion ${RELEASE}"
mkdir -p /opt/companion
curl -fsSL "$ASSET_URL" -o /tmp/companion.tar.gz
$STD tar -xzf /tmp/companion.tar.gz -C /opt/companion --strip-components=1
rm -f /tmp/companion.tar.gz
msg_ok "Downloaded and Extracted Bitfocus Companion ${RELEASE}"

msg_info "Installing udev Rules"
[[ -f /opt/companion/50-companion-headless.rules ]] && cp /opt/companion/50-companion-headless.rules /etc/udev/rules.d/
msg_ok "Installed udev Rules"

msg_info "Creating companion User"
useradd --system --no-create-home --shell /usr/sbin/nologin companion 2>/dev/null || true
mkdir -p /opt/companion-config
chown -R companion:companion /opt/companion-config
chown -R companion:companion /opt/companion
msg_ok "Created companion User"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/companion.service
[Unit]
Description=Bitfocus Companion
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=companion
ExecStart=/opt/companion/companion_headless.sh --config-dir /opt/companion-config
WorkingDirectory=/opt/companion
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=companion
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now companion
msg_ok "Created Service"

echo "${RELEASE}" >/opt/companion-config/version.txt

motd_ssh
customize
cleanup_lxc
