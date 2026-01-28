#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck
# Co-Author: havardthom
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nzbget.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  par2 \
  unrar-free
msg_ok "Installed Dependencies"

msg_info "Installing NZBGet"
setup_deb822_repo \
  "nzbgetcom" \
  "https://nzbgetcom.github.io/nzbgetcom.asc" \
  "https://nzbgetcom.github.io/deb" \
  "stable"
$STD apt install -y nzbget
sed -i "s|UnrarCmd=unrar|UnrarCmd=unrar-free|g" /var/lib/nzbget/nzbget.conf
sed -i "s|SevenZipCmd=7zz|SevenZipCmd=7z|g" /var/lib/nzbget/nzbget.conf
systemctl restart nzbget
msg_ok "Installed NZBGet"

motd_ssh
customize
cleanup_lxc
