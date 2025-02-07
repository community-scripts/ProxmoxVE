#!/usr/bin/env bash

#Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  mc \
  sudo \
  gnupg
msg_ok "Installed Dependencies"

msg_info "Setting up Zerotier-One"
curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/main/doc/contact%40zerotier.com.gpg' | gpg --import && \
if z="$(curl -s 'https://install.zerotier.com/' | gpg)"; then 
echo "$z" | sudo bash
fi
msg_ok "Setup Zerotier-One"

msg_info "Setting up UI"
curl -O https://s3-us-west-1.amazonaws.com/key-networks/deb/ztncui/1/x86_64/ztncui_0.8.14_amd64.deb
dpkg -i ztncui_0.8.14_amd64.deb
sh -c "echo ZT_TOKEN=$(cat /var/lib/zerotier-one/authtoken.secret) > /opt/key-networks/ztncui/.env"
echo HTTPS_PORT=3443 >> /opt/key-networks/ztncui/.env
echo NODE_ENV=production >> /opt/key-networks/ztncui/.env
chmod 400 /opt/key-networks/ztncui/.env
chown ztncui:ztncui /opt/key-networks/ztncui/.env
systemctl restart ztncui
msg_ok "Done setting up UI."

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"