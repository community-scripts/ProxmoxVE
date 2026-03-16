#!/usr/bin/env bash

# Author: BillyOutlast
# License: MIT | https://github.com/Heretek-AI/ProxmoxVE/raw/main/LICENSE
# Source: https://ztnet.network

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
  jq \
  git \
  openssl \
  gnupg \
  lsb-release \
  postgresql \
  postgresql-contrib
msg_ok "Installed Dependencies"

msg_info "Installing ZeroTier"
curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/main/doc/contact%40zerotier.com.gpg' | gpg --import
if z=$(curl -s 'https://install.zerotier.com/' | gpg); then
  echo "$z" | bash
fi
$STD systemctl enable --now zerotier-one
msg_ok "Installed ZeroTier"

msg_info "Installing ZTNet"
curl -s http://install.ztnet.network | bash
msg_ok "Installed ZTNet"

msg_info "Enabling ZTNet Service"
$STD systemctl enable --now ztnet
msg_ok "Started ZTNet"

motd_ssh
customize
cleanup_lxc
