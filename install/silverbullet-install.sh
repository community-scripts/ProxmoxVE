#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Dominik Siebel (dsiebel)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://silverbullet.md | Github: https://github.com/silverbulletmd/silverbullet

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "silverbullet" "silverbulletmd/silverbullet" "prebuild" "latest" "/opt/silverbullet/bin" "silverbullet-server-linux-$(arch_resolve "x86_64" "aarch64").zip"
mkdir -p /opt/silverbullet/space

RUNTIME_API_ENV=""
read -rp "${TAB3}Enable Silverbullet Runtime API? Requires Chromium (~700MB). Uses ~200MB extra RAM. (y/N): " runtime_api_prompt
if [[ "${runtime_api_prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing Chromium for Runtime API"
  $STD apt install -y chromium
  msg_ok "Installed Chromium for Runtime API"
  RUNTIME_API_ENV=$'Environment=SB_CHROME_PATH=/usr/bin/chromium\nEnvironment=SB_CHROME_DATA_DIR=/opt/silverbullet/space/.chrome-data\n'
  touch /opt/silverbullet/.runtime-api-enabled
  msg_ok "Runtime API will be enabled"
fi

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/silverbullet.service
[Unit]
Description=Silverbullet Daemon
After=syslog.target network.target

[Service]
User=root
Type=simple
${RUNTIME_API_ENV}
ExecStart=/opt/silverbullet/bin/silverbullet --hostname 0.0.0.0 --port 3000 /opt/silverbullet/space
WorkingDirectory=/opt/silverbullet
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now -q silverbullet
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
