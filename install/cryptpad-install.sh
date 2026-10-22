#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cryptpad/cryptpad

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y git
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

onlyoffice="${var_cryptpad_onlyoffice:-}"
[[ -n "$onlyoffice" ]] || read -rp "${TAB3}Install OnlyOffice components instead of CKEditor? (Y/N): " onlyoffice
fetch_and_deploy_gh_release "cryptpad" "cryptpad/cryptpad" "tarball"

msg_info "Setup CryptPad"
cd /opt/cryptpad
$STD npm ci --allow-git=all
$STD npm run install:components
if [[ "${onlyoffice,,}" =~ ^(y|yes)$ ]]; then
  $STD bash -c "./install-office.sh --accept-license"
fi
cp config/config.example.js config/config.js
cp config/infra.example.js config/infra.js
sed -i \
  -e "s|origin: \"http://localhost:3000\"|origin: \"http://${LOCAL_IP}:3000\"|" \
  -e "s|sandboxOrigin: \"http://localhost:3001\"|sandboxOrigin: \"http://${LOCAL_IP}:3001\"|" \
  -e "s|httpHost: \"localhost\"|httpHost: \"0.0.0.0\"|" \
  config/infra.js
$STD npm run build
msg_ok "Setup CryptPad"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/cryptpad.service
[Unit]
Description=CryptPad Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cryptpad
ExecStart=/usr/bin/node server
Environment='PWD="/opt/cryptpad"'
StandardOutput=journal
StandardError=journal+console
LimitNOFILE=1000000
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now cryptpad
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
