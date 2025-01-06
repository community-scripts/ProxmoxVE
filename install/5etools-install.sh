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
  gpg \
  ca-certificates \
  apache2
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

# Setup App
msg_info "Set up 5etools Base"
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/5etools-mirror-3/5etools-src/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
wget -q "https://github.com/5etools-mirror-3/5etools-src/archive/refs/tags/${RELEASE}.zip"
unzip -q "${RELEASE}.zip"
mv "5etools-src-${RELEASE:1}" /opt/5etools
cd /opt/5etools
$STD npm install
$STD npm run build
echo "${RELEASE}" >"/opt/5etools_version.txt"
msg_ok "Set up 5etools Base"

msg_info "Set up 5etools Image"
cd /opt
IMG_RELEASE=$(curl -s https://api.github.com/repos/5etools-mirror-2/5etools-img/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
curl -sSL "https://github.com/5etools-mirror-2/5etools-img/archive/refs/tags/${IMG_RELEASE}.zip" > "${IMG_RELEASE}.zip"
unzip -q "${IMG_RELEASE}.zip"
mv "5etools-img-${IMG_RELEASE:1}" /opt/5etools/img
echo "${IMG_RELEASE}" >"/opt/5etools_IMG_version.txt"
msg_ok "Set up 5etools Image"

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
msg_ok "Created Service"

msg_info "Cleaning up"
rm -rf /opt/${IMG_RELEASE}.zip
rm -rf /opt/${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
