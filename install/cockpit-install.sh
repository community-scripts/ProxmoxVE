#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: havardthom
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cockpit-project/cockpit

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Cockpit"
source /etc/os-release

cat <<EOF >/etc/apt/sources.list.d/debian-backports.sources
Types: deb deb-src
URIs: http://deb.debian.org/debian
Suites: ${VERSION_CODENAME}-backports
Components: main
Enabled: yes
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

$STD apt update
$STD apt install -t ${VERSION_CODENAME}-backports cockpit cracklib-runtime --no-install-recommends -y
sed -i "s/root//g" /etc/cockpit/disallowed-users
msg_ok "Installed Cockpit"

read -r -p "Would you like to install 45Drives' cockpit-file-sharing, cockpit-identities, and cockpit-navigator  <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  install_45drives=true
  if [[ "${VERSION_ID}" -ge 13 ]]; then
    read -r -p "Debian ${VERSION_ID} is not officially supported by 45Drives yet, would you like to continue anyway? <y/N> " prompt
    if [[ ! "${prompt,,}" =~ ^(y|yes)$ ]]; then
      install_45drives=false
    fi
  fi
  if [[ "$install_45drives" == "true" ]]; then
    msg_info "Installing 45Drives' cockpit extensions"
    curl -fsSL https://repo.45drives.com/key/gpg.asc | gpg --pinentry-mode loopback --batch --yes --dearmor -o /usr/share/keyrings/45drives-archive-keyring.gpg
    cat <<EOF >/etc/apt/sources.list.d/45drives-enterprise.sources
Types: deb
URIs: https://repo.45drives.com/enterprise/debian
Suites: bookworm
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/45drives-archive-keyring.gpg
EOF

    $STD apt update
    $STD apt install cockpit-file-sharing cockpit-identities cockpit-navigator -y
    msg_ok "Installed 45Drives' cockpit extensions"
  fi
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
msg_ok "Cleaned"
