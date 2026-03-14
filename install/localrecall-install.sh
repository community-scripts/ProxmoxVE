#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mudler/LocalRecall

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl ca-certificates git
msg_ok "Installed Dependencies"

GO_VERSION="1.24" setup_go

msg_info "Building LocalRecall from Source"
cd /tmp
$STD git clone https://github.com/mudler/LocalRecall.git
cd LocalRecall
$STD go build -o localrecall .
mv localrecall /usr/local/bin/localrecall
cd /tmp
rm -rf LocalRecall
msg_ok "Built LocalRecall from Source"

msg_info "Setting Up Application"
mkdir -p /opt/localrecall/data
mkdir -p /opt/localrecall/assets
msg_ok "Set Up Application"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/localrecall.service
[Unit]
Description=LocalRecall - Knowledge Base Management API
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/localrecall
ExecStart=/usr/local/bin/localrecall
Restart=on-failure
RestartSec=5
Environment=COLLECTION_DB_PATH=/opt/localrecall/data
Environment=FILE_ASSETS=/opt/localrecall/assets
Environment=LISTENING_ADDRESS=:8080

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now localrecall
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
