#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# Co-Author: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lldap/lldap

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing lldap"
OS_ID=$(get_os_info id)
OS_VERSION=$(get_os_info version)
if [ "$OS_ID" == "ubuntu" ]; then
  DISTRO="xUbuntu"
else
  DISTRO="${OS_ID^}"
fi
curl -fsSL https://download.opensuse.org/repositories/home:Masgalor:LLDAP/${DISTRO}_${OS_VERSION}/Release.key | gpg --dearmor >/usr/share/keyrings/home_Masgalor_LLDAP.gpg
cat <<EOF >/etc/apt/sources.list.d/home:Masgalor:LLDAP.sources
Types: deb
URIs: http://download.opensuse.org/repositories/home:/Masgalor:/LLDAP/${DISTRO}_${OS_VERSION}/
Suites: /
Signed-By: /usr/share/keyrings/home_Masgalor_LLDAP.gpg
EOF
$STD apt update
$STD apt install -y lldap
systemctl enable -q --now lldap
msg_ok "Installed lldap"

motd_ssh
customize
cleanup_lxc
