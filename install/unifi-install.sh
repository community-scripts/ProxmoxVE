#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ui.com/download/unifi

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y apt-transport-https
msg_ok "Installed Dependencies"

msg_info "Installing Eclipse Temurin JRE"
curl -fsSL "https://packages.adoptium.net/artifactory/api/gpg/key/public" | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg
cat <<EOF | sudo tee /etc/apt/sources.list.d/adoptium.sources >/dev/null
Types: deb
URIs: https://packages.adoptium.net/artifactory/deb
Suites: bookworm
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/adoptium.gpg
EOF
$STD apt update
$STD apt install -y temurin-17-jre
msg_ok "Installed Eclipse Temurin JRE"

if ! grep -q -m1 'avx[^ ]*' /proc/cpuinfo; then
  msg_ok "No AVX Support Detected"
  msg_info "Installing MongoDB 4.4"
  if ! dpkg -l | grep -q "libssl1.1"; then
    curl -fsSL "https://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.1_1.1.1w-0+deb11u4_amd64.deb" -o "libssl1.1_1.1.1w-0+deb11u4_amd64.deb"
    $STD dpkg -i libssl1.1_1.1.1w-0+deb11u4_amd64.deb
  fi
  curl -fsSL "https://www.mongodb.org/static/pgp/server-4.4.asc" | gpg --dearmor -o /usr/share/keyrings/mongodb-server-4.4.gpg
  cat <<EOF | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.sources >/dev/null
Types: deb
URIs: https://repo.mongodb.org/apt/debian
Suites: buster/mongodb-org/4.4
Components: main
Signed-By: /usr/share/keyrings/mongodb-server-4.4.gpg
EOF
  $STD apt update
  $STD apt install -y mongodb-org
else
  msg_info "Installing MongoDB 7.0"
  curl -fsSL "https://www.mongodb.org/static/pgp/server-7.0.asc" | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
  cat <<EOF | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.sources >/dev/null
Types: deb
URIs: http://repo.mongodb.org/apt/debian
Suites: bookworm/mongodb-org/7.0
Components: main
Signed-By: /usr/share/keyrings/mongodb-server-7.0.gpg
EOF
  $STD apt update
  $STD apt install -y mongodb-org
fi
msg_ok "Installed MongoDB"

msg_info "Installing UniFi Network Server"
curl -fsSL "https://dl.ui.com/unifi/unifi-repo.gpg" -o "/usr/share/keyrings/unifi-repo.gpg"
cat <<EOF | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.sources >/dev/null
Types: deb
URIs: https://www.ui.com/downloads/unifi/debian
Suites: stable
Components: ubiquiti
Architectures: amd64
Signed-By: /usr/share/keyrings/unifi-repo.gpg
EOF
$STD apt update
$STD apt install -y unifi
msg_ok "Installed UniFi Network Server"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
