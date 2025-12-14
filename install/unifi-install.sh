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

JAVA_VERION="17" setup_java
setup_deb822_repo \
  "unifi" \
  "https://dl.ui.com/unifi/unifi-repo.gpg" \
  "https://www.ui.com/downloads/unifi/debian" \
  "stable" \
  "ubiquiti" \
  "amd64"

if ! grep -q -m1 'avx[^ ]*' /proc/cpuinfo; then
  msg_warn "No AVX Support Detected. MongoDB v4.4 will be installed"
  if ! dpkg -l | grep -q "libssl1.1"; then
    curl -fsSL "https://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.1_1.1.1w-0+deb11u4_amd64.deb" -o "libssl1.1_1.1.1w-0+deb11u4_amd64.deb"
    $STD dpkg -i libssl1.1_1.1.1w-0+deb11u4_amd64.deb
  fi
  MONGO_VERSION="4.4" setup_mongodb
else
  MONGO_VERSION="7.0" setup_mongodb
fi
msg_ok "Installed MongoDB"

msg_info "Installing UniFi Network Server"
$STD apt install -y unifi
msg_ok "Installed UniFi Network Server"

motd_ssh
customize
cleanup_lxc
