#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://lemonade-server.ai	

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "lemonade" "lemonade-sdk/lemonade" "binary"

msg_info "Configuring Service"
sed -i -e "s/^#LEMONADE_HOST=.*/LEMONADE_HOST=${LOCAL_IP}/" \
       -e "s/^#LEMONADE_PORT=.*/LEMONADE_PORT=8000/" \
       /etc/lemonade/lemonade.conf
mkdir -p /etc/systemd/system/lemonade-server.service.d
cat > /etc/systemd/system/lemonade-server.service.d/override.conf << 'EOF'
[Service]
User=root
Group=root
ProtectHome=no
EOF
systemctl daemon-reload
msg_ok "Configured Service"

msg_info "Enabling Service"
systemctl enable -q --now lemonade-server
msg_ok "Enabled Service"

motd_ssh
customize
cleanup_lxc
