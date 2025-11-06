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

ASTERISK_VERSIONS_URL="https://www.asterisk.org/downloads/asterisk/all-asterisk-versions/"
html=$(curl -fsSL "$ASTERISK_VERSIONS_URL")

LTS_VERSION=""
for major in 20 22 24 26; do
  block=$(echo "$html" | awk "/Asterisk $major - LTS/,/<ul>/" || true)
  ver=$(echo "$block" | grep -oE 'Download Latest - [0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1 | sed -E 's/.* - //' || true)
  if [ -n "$ver" ]; then
    LTS_VERSION="$LTS_VERSION $ver"
  fi
  unset ver block
done
LTS_VERSION=$(echo "$LTS_VERSION" | xargs | tr ' ' '\n' | sort -V | tail -n1)

STD_VERSION=""
for major in 21 23 25 27; do
  block=$(echo "$html" | grep -A 20 "Asterisk $major</h3>" | head -n 20 || true)
  ver=$(echo "$block" | grep -oE 'Download (Latest - )?'"$major"'\.[0-9]+\.[0-9]+' | head -n1 | sed -E 's/Download (Latest - )?//' || true)
  if [ -n "$ver" ]; then
    STD_VERSION="$STD_VERSION $ver"
  fi
  unset ver block
done
STD_VERSION=$(echo "$STD_VERSION" | xargs | tr ' ' '\n' | sort -V | tail -n1)

cert_block=$(echo "$html" | awk '/Certified Asterisk/,/<ul>/')
CERT_VERSION=$(echo "$cert_block" | grep -oE 'Download Latest - [0-9]+\.[0-9]+-cert[0-9]+' | head -n1 | sed -E 's/.* - //' || true)

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
  RELEASE="certified-asterisk-${ASTERISK_VERSION}.tar.gz"
  DOWNLOAD_URL="https://downloads.asterisk.org/pub/telephony/certified-asterisk/$RELEASE"
else
  RELEASE="asterisk-${ASTERISK_VERSION}.tar.gz"
  DOWNLOAD_URL="https://downloads.asterisk.org/pub/telephony/asterisk/$RELEASE"
fi

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

msg_info "Downloading Asterisk"
temp_file=$(mktemp)
curl -fsSL "$DOWNLOAD_URL" -o "$temp_file"
mkdir -p /opt/asterisk
tar zxf "$temp_file" --strip-components=1 -C /opt/asterisk
cd /opt/asterisk
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

msg_info "Cleaning up"
rm -f "$temp_file"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
