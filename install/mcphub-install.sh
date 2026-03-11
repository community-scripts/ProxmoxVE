#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/samanhappy/mcphub | Docs: https://docs.mcphubx.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="22" setup_nodejs

msg_info "Installing MCPHub"
$STD npm install -g @samanhappy/mcphub
msg_ok "Installed MCPHub"

msg_info "Creating Default Configuration"
mkdir -p /opt/mcphub
cat <<EOF >/opt/mcphub/mcp_settings.json
{
  "mcpServers": {
    "time": {
      "command": "npx",
      "args": ["-y", "time-mcp"]
    }
  }
}
EOF
msg_ok "Created Default Configuration"

msg_info "Creating Service"
NPM_GLOBAL_BIN="$(npm prefix -g)/bin"
MCPHUB_BIN="${NPM_GLOBAL_BIN}/mcphub"
cat <<EOF >/etc/systemd/system/mcphub.service
[Unit]
Description=MCPHub
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/mcphub
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=MCPHUB_SETTING_PATH=/opt/mcphub/mcp_settings.json
ExecStart=${MCPHUB_BIN}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mcphub
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
