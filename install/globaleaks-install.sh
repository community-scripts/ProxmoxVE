#!/usr/bin/env bash
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Giovanni Pellerano (evilaliv3)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/globaleaks/globaleaks-whistleblowing-software

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setup GlobaLeaks"
DISTRO_CODENAME="$(awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release)"
curl -fsSL https://deb.globaleaks.org/globaleaks.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/globaleaks.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/globaleaks.gpg] http://deb.globaleaks.org $DISTRO_CODENAME/" >/etc/apt/sources.list.d/globaleaks.list
echo 'APPARMOR_SANDBOXING=0' >/etc/default/globaleaks
$STD apt update
$STD apt -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold install globaleaks
msg_ok "Setup GlobaLeaks"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
