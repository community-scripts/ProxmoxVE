#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
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

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  mc \
  sudo \
  git \
  apache2
msg_ok "Installed Dependencies"

# Setup App
msg_info "Set up base 5etools"
RELEASE=$(curl -s https://api.github.com/repos/5etools-mirror-3/5etools-src/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q "https://github.com/5etools-mirror-3/5etools-src/archive/refs/tags/${RELEASE}.zip"
unzip -q "${RELEASE}.zip"
mv "5etools-src-${RELEASE:1}" /opt/5etools
echo "${RELEASE}" >"/opt/5etools_version.txt"
rm "${RELEASE}.zip"
msg_ok "Set up base 5etools"

msg_info "Set up 5etools images"
IMG_RELEASE=$(curl -s https://api.github.com/repos/5etools-mirror-2/5etools-img/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
curl -sSL "https://github.com/5etools-mirror-2/5etools-img/archive/refs/tags/${IMG_RELEASE}.zip" > "${IMG_RELEASE}.zip"
unzip -q "${IMG_RELEASE}.zip"
mv "5etools-img-${IMG_RELEASE:1}" /opt/5etools/img
echo "${IMG_RELEASE}" >"/opt/5etools_IMG_version.txt"
rm "${IMG_RELEASE}.zip"
msg_ok "Set up 5etools images"

msg_info "Creating Service"
cat <<EOF >> /etc/apache2/apache2.conf
<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Allow from all
</Location>
EOF
rm -rf /var/www/html
ln -s "/opt/5etools" /var/www/html

chown -R www-data: "/opt/5etools"
chmod -R 755 "/opt/5etools"
apache2ctl start
msg_ok "Creating Service"
# Cleanup
msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
