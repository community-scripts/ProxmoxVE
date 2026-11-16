#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://yunohost.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  apt-transport-https \
  lsb-release \
  ca-certificates
msg_ok "Installed Dependencies"

confirm_external_installer "https://yunohost.org/" "https://install.yunohost.org"

msg_info "Installing YunoHost (Patience)"
touch /etc/.pve-ignore.resolv.conf
curl -fsSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
$STD bash <(curl -fsSL https://install.yunohost.org) -a
msg_ok "Installed YunoHost"

motd_ssh
customize
cleanup_lxc
