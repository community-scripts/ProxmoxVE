#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: michelroegl-brunner
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://asterisk.org

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  libsrtp2-dev \
  build-essential \
  libedit-dev \
  uuid-dev \
  libjansson-dev \
  libxml2-dev \
  libsqlite3-dev
msg_ok "Installed Dependencies"

msg_info "Downloading Asterisk"
RELEASE=$(curl -fsSL https://downloads.asterisk.org/pub/telephony/asterisk/ | grep -o 'asterisk-[0-9]\+-current\.tar\.gz' | sort -V | tail -n1)
temp_file=$(mktemp)
curl -fsSL "https://downloads.asterisk.org/pub/telephony/asterisk/${RELEASE}" -o "$temp_file"
mkdir -p /opt/asterisk
tar zxf "$temp_file" --strip-components=1 -C /opt/asterisk
cd /opt/asterisk
msg_ok "Downloaded Asterisk"

msg_info "Installing Asterisk"
$STD ./contrib/scripts/install_prereq install
$STD ./configure
$STD make -j$(nproc)
$STD make install
$STD make config
$STD make install-logrotate
$STD make samples
mkdir -p /etc/radiusclient-ng/
ln /etc/radcli/radiusclient.conf /etc/radiusclient-ng/radiusclient.conf
systemctl enable -q --now asterisk
msg_ok "Installed Asterisk"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
