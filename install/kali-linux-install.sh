#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  gnupg \
  dirmngr
msg_ok "Installed Dependencies"

msg_info "Adding Kali Linux Repository"
wget -q -O - https://archive.kali.org/archive-key.asc | gpg --import -q
echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" > /etc/apt/sources.list.d/kali.list
$STD gpg --export ED444FF07D8D0BF6  > /etc/apt/trusted.gpg.d/kali-rolling.gpg
msg_ok "Added Kali Linux Repository"

msg_info "Updating System"
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NOWARNINGS=yes
$STD apt-get update
$STD apt-get -y upgrade
msg_ok "Updated System"	

msg_info "Installing Kali Linux"
$STD apt-get install -y kali-linux-core kali-linux-default
msg_ok "Installed Kali Linux"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
