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
  apache2 \
  git
msg_ok "Installed Dependencies"

# Setup App
msg_info "Setup Pf2eTools"
RELEASE=$(curl -s https://api.github.com/repos/Pf2eToolsOrg/Pf2eTools/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q "https://github.com/Pf2eToolsOrg/Pf2eTools/archive/refs/tags/${RELEASE}.zip"
unzip -q "${RELEASE}.zip"
mv "Pf2eTools-${RELEASE:1}" /opt/Pf2eTools
echo "${RELEASE}" >/opt/Pf2eTools_version.txt
msg_ok "Set up Pf2eTools"

msg_info "Creating Service"
cat <<EOF >> /etc/apache2/apache2.conf
<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Allow from all
</Location>
EOF
rm -rf /var/www/html
ln -s "/opt/Pf2eTools" /var/www/html

chown -R www-data: "/opt/Pf2eTools"
chmod -R 755 "/opt/Pf2eTools"
apache2ctl start
msg_ok "Creating Service"
# Cleanup
msg_info "Cleaning up"
rm "${RELEASE}.zip"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
