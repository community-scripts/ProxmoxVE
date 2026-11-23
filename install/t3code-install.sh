#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: lukdz
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pingdotgg/t3code

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  build-essential \
  bubblewrap
msg_ok "Installed Dependencies"

NODE_VERSION="26" setup_nodejs

msg_info "Installing T3 Code and Provider CLIs"
$STD npm install -g \
  t3 \
  @openai/codex \
  @anthropic-ai/claude-code \
  @xai-official/grok \
  opencode-ai
msg_ok "Installed T3 Code and Provider CLIs"

fetch_and_deploy_gh_release "gh" "cli/cli" "binary"

msg_info "Creating Service"
mkdir -p /opt/t3code
cat <<EOF >/etc/systemd/system/t3code.service
[Unit]
Description=T3 Code Server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
Environment=PATH=/usr/local/bin:/usr/bin:/bin
Environment=T3CODE_TELEMETRY_ENABLED=false
# Allow Claude Full access mode as root inside the LXC.
Environment=IS_SANDBOX=1
WorkingDirectory=/opt/t3code
ExecStart=/usr/bin/t3 serve --host 0.0.0.0 --base-dir /opt/t3code
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now t3code
for _ in {1..60}; do
  [[ -f /opt/t3code/userdata/server-runtime.json ]] && curl -s -o /dev/null http://127.0.0.1:3773 && break
  sleep 2
done
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
