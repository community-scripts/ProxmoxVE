#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mudler/skillserver

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  git \
  ca-certificates
msg_ok "Installed Dependencies"

GO_VERSION="1.25" setup_go

fetch_and_deploy_gh_release "skillserver" "mudler/skillserver" "tarball" "latest" "/opt/skillserver"

msg_info "Building Application"
cd /opt/skillserver || exit
$STD go build -o /usr/local/bin/skillserver ./cmd/skillserver
msg_ok "Built Application"

msg_info "Creating Service"
mkdir -p /opt/skillserver/skills
cat <<EOF >/etc/systemd/system/skillserver.service
[Unit]
Description=SkillServer - MCP/REST server for AI agent skills
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/skillserver
ExecStart=/usr/local/bin/skillserver
Restart=on-failure
RestartSec=5
Environment=SKILLSERVER_DIR=/opt/skillserver/skills
Environment=SKILLSERVER_PORT=8080

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now skillserver
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
