#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: tomfrenzel
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/thedevs-network/kutt

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

echo "${TAB3}How would you like to handle SSL termination?"
echo "${TAB3}[i]-Internal (self-signed SSL Certificate)   [e]-External (use your own reverse proxy)"
read -rp "${TAB3}Enter your choice <i/e> (default: i): " ssl_choice
ssl_choice=${ssl_choice:-i}
case "${ssl_choice,,}" in
i)
  import_local_ip
  DEFAULT_HOST="$LOCAL_IP"

  msg_info "Configuring Caddy"
  $STD apt install -y caddy
  cat <<EOF >/etc/caddy/Caddyfile
$LOCAL_IP {
    reverse_proxy localhost:3000
}
EOF
  systemctl restart caddy
  msg_ok "Configured Caddy"
  ;;
e)
  read -r -p "${TAB3}Enter the hostname you want to use for Kutt (eg. kutt.example.com): " custom_host
  if [[ "$custom_host" ]]; then
    DEFAULT_HOST="$custom_host"
  fi
  ;;
esac

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "kutt" "thedevs-network/kutt" "tarball"

msg_info "Configuring Kutt"
cd /opt/kutt
cp .example.env ".env"
sed -i "s|JWT_SECRET=|JWT_SECRET=$(openssl rand -base64 32)|g" ".env"
sed -i "s|DEFAULT_DOMAIN=.*|DEFAULT_DOMAIN=$DEFAULT_HOST|g" ".env"
$STD npm install
$STD npm run migrate
msg_ok "Configured Kutt"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/kutt.service
[Unit]
Description=Kutt server
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/kutt
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now kutt
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
