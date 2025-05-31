#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.tp-link.com/us/support/download/omada-software-controller/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y jsvc
msg_ok "Installed Dependencies"

msg_info "Checking CPU Features"
if lscpu | grep -q 'avx'; then
  MONGODB_VERSION="7.0"
  msg_ok "AVX detected: Using MongoDB 7.0"
else
  msg_error "No AVX detected: TP-Link Canceled Support for Old MongoDB for Debian 12\n https://www.tp-link.com/baltic/support/faq/4160/"
  exit 0
fi

msg_info "Installing Azul Zulu Java"
curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xB1998361219BD9C9" -o "/etc/apt/trusted.gpg.d/zulu-repo.asc"
curl -fsSL "https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-3_all.deb" -o zulu-repo.deb
$STD dpkg -i zulu-repo.deb
$STD apt-get update
$STD apt-get -y install zulu21-jre-headless
msg_ok "Installed Azul Zulu Java"

msg_info "Installing libssl (if needed)"
if ! dpkg -l | grep -q 'libssl1.1'; then
  curl -fsSL "https://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.1_1.1.1w-0+deb11u3_amd64.deb" -o "/tmp/libssl.deb"
  $STD dpkg -i /tmp/libssl.deb
  rm -f /tmp/libssl.deb
  msg_ok "Installed libssl1.1"
fi

msg_info "Installing MongoDB $MONGODB_VERSION"
curl -fsSL "https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc" | gpg --dearmor >/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg] http://repo.mongodb.org/apt/debian $(grep '^VERSION_CODENAME=' /etc/os-release | cut -d'=' -f2)/mongodb-org/${MONGODB_VERSION} main" >/etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list
$STD apt-get update
$STD apt-get install -y mongodb-org
msg_ok "Installed MongoDB $MONGODB_VERSION"

msg_info "Installing Omada Controller"
OMADA_URL=$(curl -fsSL "https://support.omadanetworks.com/en/download/software/omada-controller/" |
  grep -o 'https://static\.tp-link\.com/upload/software/[^"]*linux_x64[^"]*\.deb' |
  head -n1)
OMADA_PKG=$(basename "$OMADA_URL")
curl -fsSL "$OMADA_URL" -o "$OMADA_PKG"
$STD dpkg -i "$OMADA_PKG"
msg_ok "Installed Omada Controller"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "$OMADA_PKG" zulu-repo.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
