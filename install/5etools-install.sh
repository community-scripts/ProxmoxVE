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
  apache2 \
  unzip

msg_ok "Installed Dependencies"

# Setup App
msg_info "Setup 5etools"
echo "<Location /server-status>\n"\
"    SetHandler server-status\n"\
"    Order deny,allow\n"\
"    Allow from all\n"\
"</Location>\n"\
>> /etc/apache2/apache2.conf

rm -rf /var/www/html
RELEASE=$(curl -s https://api.github.com/repos/5etools-mirror-3/5etools-src/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q "https://github.com/5etools-mirror-3/5etools-src/archive/refs/tags/${RELEASE}.zip"
unzip -q "${RELEASE}.zip" -d "/opt/5etools"
wget -q "https://github.com/5etools-mirror-2/5etools-img/archive/refs/tags/${RELEASE}.zip"
unzip -q "${RELEASE}.zip" -d "/opt/5etools/img"
ln -s "/opt/5etools" /var/www/html

chown -R www-data: "/opt/5etools"
chmod -R 755 "/opt/5etools"

# Cleanup
msg_info "Cleaning up"
rm -rf "${RELEASE}.zip"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

# Starting httpd
msg_info "Starting apache"
apache2ctl start
msg_ok "Started apache"

motd_ssh
customize
