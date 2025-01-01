#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: TheRealVira
# License: MIT
# Source: https://5e.tools/

# Import Functions und Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
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
echo "<Location /server-status>\n""\
    SetHandler server-status\n""\
    Order deny,allow\n""\
    Allow from all\n""\
</Location>\n" \
  >>/etc/apache2/apache2.conf

rm -rf /var/www/html
msg_info "Setting up 5etools"
git clone https://github.com/5etools-mirror-3/5etools-src /opt/5etools
msg_ok "Set up 5etools"
msg_info "Setting up 5etools images"
cd /opt/5etools
git submodule add -f https://github.com/5etools-mirror-2/5etools-img "img"
git pull --recurse-submodules --jobs=10
cd ~
msg_info "Set up 5etools images"
ln -s "/opt/5etools" /var/www/html

chown -R www-data: "/opt/5etools"
chmod -R 755 "/opt/5etools"

# Cleanup
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

# Starting httpd
msg_info "Starting apache"
apache2ctl start
msg_ok "Started apache"

motd_ssh
customize
