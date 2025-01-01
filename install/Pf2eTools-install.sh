#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: TheRealVira
# License: MIT
# Source: https://pf2etools.com/

# Import Functions und Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  mc \
  sudo \
  git \
  apache2
msg_ok "Installed Dependencies"

# Setup App
msg_info "Setup Pf2eTools"
rm -rf /var/www/html
git config --global http.postBuffer 1048576000
git config --global https.postBuffer 1048576000
git clone https://github.com/Pf2eToolsOrg/Pf2eTools /opt/Pf2eTools
msg_ok "Set up Pf2eTools"

msg_info "Creating Service"
cat <<EOF >> /etc/apache2/apache2.conf
<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Allow from all
</Location>
EOF
ln -s "/opt/Pf2eTools" /var/www/html

chown -R www-data: "/opt/Pf2eTools"
chmod -R 755 "/opt/Pf2eTools"
apache2ctl start
msg_ok "Creating Service"
# Cleanup
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize