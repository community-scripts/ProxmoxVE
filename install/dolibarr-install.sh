#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Dolibarr/dolibarr/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  php-imap \
  debconf-utils \
  mariadb-server
msg_ok "Installed Dependencies"

msg_info "Setting up Database"
ROOT_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$ROOT_PASS'); flush privileges;"
{
    echo "Dolibarr DB Credentials"
    echo "MariaDB Root Password: $ROOT_PASS"
} >> ~/dolibarr.creds
msg_ok "Set up database"

msg_info "Setup Dolibarr"
BASE="https://sourceforge.net/projects/dolibarr/files/Dolibarr%20installer%20for%20Debian-Ubuntu%20(DoliDeb)/"
RELEASE=$(curl -s "$BASE" | grep -oP '(?<=/Dolibarr%20installer%20for%20Debian-Ubuntu%20%28DoliDeb%29/)[^/"]+' | head -n1)
FILE=$(curl -s "${BASE}${RELEASE}/" | grep -oP 'dolibarr_[^"]+_all.deb' | head -n1)
wget -q "https://netcologne.dl.sourceforge.net/project/dolibarr/Dolibarr%20installer%20for%20Debian-Ubuntu%20(DoliDeb)/${RELEASE}/${FILE}?viasf=1" -O "$FILE"
echo "dolibarr dolibarr/reconfigure-webserver multiselect apache2" | debconf-set-selections
$STD apt-get install ./$FILE -y
$STD apt install -f
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Setup Dolibarr"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf ~/$FILE
$STD apt-get autoremove
$STD apt-get autoclean
msg_ok "Cleaned"
