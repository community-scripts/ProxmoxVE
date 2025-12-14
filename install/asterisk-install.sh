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
$STD apt install -y \
  libsrtp2-dev \
  build-essential \
  libedit-dev \
  uuid-dev \
  libjansson-dev \
  libxml2-dev \
  libsqlite3-dev
msg_ok "Installed Dependencies"

msg_info "Fetching Asterisk Versions"
ASTERISK_LIST=$(curl -fsSL https://downloads.asterisk.org/pub/telephony/asterisk/ \
  | grep -oE 'asterisk-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz' \
  | sed 's/asterisk-//' \
  | sed 's/\.tar\.gz//' \
  | sort -V)
# LTS: Major 20, 22, 24, 26
LTS_VERSION=$(echo "$ASTERISK_LIST" | grep -E '^2(0|2|4|6)\.' | tail -n1 || true)
# Standard: Major 21, 23, 25, 27
STD_VERSION=$(echo "$ASTERISK_LIST" | grep -E '^2(1|3|5|7)\.' | tail -n1 || true)
CERT_VERSION=$(curl -fsSL https://downloads.asterisk.org/pub/telephony/certified-asterisk/ \
  | grep -oE 'asterisk-certified-[0-9]+\.[0-9]+-cert[0-9]+\.tar\.gz' \
  | sed -E 's/asterisk-certified-//' \
  | sed -E 's/\.tar\.gz//' \
  | sort -V | tail -n1 || true)
msg_ok "Fetched Versions"

cat <<EOF
Choose Asterisk version to install:
1) Latest Standard ($STD_VERSION)
2) Latest LTS ($LTS_VERSION)
3) Latest Certified ($CERT_VERSION)
EOF
read -rp "Enter choice [1-3]: " ASTERISK_CHOICE

CERTIFIED=0
case "$ASTERISK_CHOICE" in
  2)
    ASTERISK_VERSION="$LTS_VERSION"
    ;;
  3)
    ASTERISK_VERSION="$CERT_VERSION"
    CERTIFIED=1
    ;;
  *)
    ASTERISK_VERSION="$STD_VERSION"
    ;;
esac

if [[ "$CERTIFIED" == "1" ]]; then
  RELEASE="asterisk-certified-${ASTERISK_VERSION}.tar.gz"
  DOWNLOAD_URL="https://downloads.asterisk.org/pub/telephony/certified-asterisk/$RELEASE"
else
  RELEASE="asterisk-${ASTERISK_VERSION}.tar.gz"
  DOWNLOAD_URL="https://downloads.asterisk.org/pub/telephony/asterisk/$RELEASE"
fi

msg_info "Downloading Asterisk ($RELEASE)"
temp_file=$(mktemp)
curl -fsSL "$DOWNLOAD_URL" -o "$temp_file"
mkdir -p /opt/asterisk
tar zxf "$temp_file" --strip-components=1 -C /opt/asterisk
cd /opt/asterisk
rm -f "$temp_file"
msg_ok "Downloaded Asterisk ($RELEASE)"

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
cleanup_lxc
