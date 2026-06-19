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
$STD apt install -y libusb-1.0-0
msg_ok "Installed Dependencies"

msg_info "Fetching Latest Bitfocus Companion Release"
RELEASE_JSON=$(curl -fsSL "https://api.bitfocus.io/v1/product/companion/packages?limit=20")
COMPANION_ARCH=$(arch_resolve "x64" "arm64")
PACKAGE_JSON=$(echo "$RELEASE_JSON" | jq -c \
  --arg target "linux-$(arch_resolve "tgz" "arm64-tgz")" \
  --arg arch "linux-$COMPANION_ARCH" \
  '(if type == "array" then . else .packages end) | [.[] | select(.target==$target and (.uri | contains($arch)))] | first')
RELEASE=$(echo "$PACKAGE_JSON" | jq -r '.version // empty')
ASSET_URL=$(echo "$PACKAGE_JSON" | jq -r '.uri // empty')
if [[ -z "$RELEASE" || -z "$ASSET_URL" ]]; then
  msg_error "Could not resolve a matching Linux ${COMPANION_ARCH} Companion package from the Bitfocus API."
  exit 1
fi
msg_ok "Found Companion ${RELEASE}"

fetch_and_deploy_from_url "$ASSET_URL" "/opt/bitfocus-companion"

msg_info "Installing udev Rules"
if [[ -f /opt/bitfocus-companion/50-companion-headless.rules ]]; then
  cp /opt/bitfocus-companion/50-companion-headless.rules /etc/udev/rules.d/
  udevadm control --reload-rules
  udevadm trigger
fi
msg_ok "Installed udev Rules"

mkdir -p /opt/bitfocus-companion-config

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/bitfocus-companion.service
[Unit]
Description=Bitfocus Companion
After=network.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/opt/bitfocus-companion/companion_headless.sh --config-dir /opt/bitfocus-companion-config
WorkingDirectory=/opt/bitfocus-companion
Restart=on-failure
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bitfocus-companion
msg_ok "Created Service"

echo "${RELEASE}" >~/.bitfocus-companion

motd_ssh
customize
cleanup_lxc
