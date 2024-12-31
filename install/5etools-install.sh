#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: TheRealVira
# License: MIT
# Source: https://5e.tools/

# Import Functions und Setup
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Installing Dependencies with the 3 core dependencies (curl;sudo;mc)
msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  git \
  jq \
  apache2

msg_ok "Installed Dependencies"

# Setup App
msg_info "Setup 5etools"
echo "<Location /server-status>\n"\
"    SetHandler server-status\n"\
"    Order deny,allow\n"\
"    Allow from all\n"\
"</Location>\n"\
>> /usr/local/apache2/conf/httpd.conf

rm /usr/local/apache2/htdocs/index.html
wget -q "https://github.com/5etools-mirror-3/5etools-src/archive/refs/tags/${RELEASE}.zip"
unzip -q "${RELEASE}.zip"
mv "${APP}-src-${RELEASE}/" "/opt/${APP}"

chown -R www-data: "/opt/${APP}"
chmod -R 755 "/opt/${APP}"

# Cleaning up
msg_info "Cleaning Up"
rm -rf "v${RELEASE}.zip"
msg_ok "Setup 5etools"

# Starting httpd
msg_info "Starting httpd"
httpd-foreground
msg_ok "Started httpd"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
rm -f "/opt/v${RELEASE}.zip"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
