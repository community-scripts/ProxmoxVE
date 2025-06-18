#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://shinobi.video/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y make zip net-tools git
$STD apt-get install -y gcc g++ cmake
$STD apt-get install -y ca-certificates
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs
setup_mariadb

msg_info "Installing FFMPEG"
$STD apt-get install -y ffmpeg
msg_ok "Installed FFMPEG"

msg_info "Cloning Shinobi"
cd /opt
$STD git clone https://gitlab.com/Shinobi-Systems/Shinobi.git -b master Shinobi
cd Shinobi
gitVersionNumber=$(git rev-parse HEAD)
theDateRightNow=$(date)
touch version.json
chmod 777 version.json
echo '{"Product" : "'"Shinobi"'" , "Branch" : "'"master"'" , "Version" : "'"$gitVersionNumber"'" , "Date" : "'"$theDateRightNow"'" , "Repository" : "'"https://gitlab.com/Shinobi-Systems/Shinobi.git"'"}' >version.json
msg_ok "Cloned Shinobi"

msg_info "Installing Database"
sqluser="root"
sqlpass="root"
echo "mariadb-server mariadb-server/root_password password $sqlpass" | debconf-set-selections
echo "mariadb-server mariadb-server/root_password_again password $sqlpass" | debconf-set-selections
service mysql start
$STD mariadb -u "$sqluser" -p"$sqlpass" -e "source sql/user.sql" || true
msg_ok "Installed Database"

msg_info "Installing Shinobi"
cp conf.sample.json conf.json
cronKey=$(head -c 1024 </dev/urandom | sha256sum | awk '{print substr($1,1,29)}')
sed -i -e 's/Shinobi/'"$cronKey"'/g' conf.json
cp super.sample.json super.json
$STD npm i npm -g
$STD npm install --unsafe-perm
$STD npm install pm2@latest -g
chmod -R 755 .
touch INSTALL/installed.txt
ln -s /opt/Shinobi/INSTALL/shinobi /usr/bin/shinobi
node /opt/Shinobi/tools/modifyConfiguration.js addToConfig="{\"cron\":{\"key\":\"$(head -c 64 </dev/urandom | sha256sum | awk '{print substr($1,1,60)}')\"}}" &>/dev/null
$STD pm2 start camera.js
$STD pm2 start cron.js
$STD pm2 startup
$STD pm2 save
$STD pm2 list
msg_ok "Installed Shinobi"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
