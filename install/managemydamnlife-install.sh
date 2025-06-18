#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/intri-in/manage-my-damn-life-nextjs

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

NODE_VERSION="20" setup_nodejs
MYSQL_VERSION="8.0" setup_mysql

msg_info "Setting up Database"
DB_NAME="mmdl"
DB_USER="mmdl"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mysql -u root -e "CREATE DATABASE $DB_NAME;"
$STD mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED by '$DB_PASS';"
$STD mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "Manage My Damn Life Credentials"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
  echo "Database Name: $DB_NAME"
} >>~/mmdl.creds
msg_ok "Set up Database"

msg_info "Installing ${APPLICATION}"
RELEASE=$(curl -fsSL https://api.github.com/repos/intri-in/manage-my-damn-life-nextjs/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSLO "https://github.com/intri-in/manage-my-damn-life-nextjs/archive/refs/tags/v${RELEASE}.zip"
unzip -q v"$RELEASE".zip
mv manage-my-damn-life-nextjs-"$RELEASE"/ /opt/mmdl
cp /opt/mmdl/sample.env.local /opt/mmdl/.env

sed -i -e 's|db|localhost|' \
  -e "s|myuser|${DB_USER}|" \
  -e "s|mypassword|${DB_PASS}|" \
  -e 's|5433|3306|' \
  -e 's|DB_DIALECT=postgres|DB_DIALECT=mysql|' \
  -e "s|sample_install_mmdm|${DB_NAME}|" \
  -e "s|=PASSWORD|=$(openssl rand -base64 40 | tr -dc 'a-zA-Z0-9' | head -c40)|" \
  /opt/mmdl/.env

cd /opt/mmdl
export NEXT_TELEMETRY_DISABLE=1
export CI="true"
$STD npm install
$STD npm run migrate
$STD npm run build
echo "${RELEASE}" >/opt/mmdl_version.txt
msg_ok "Installed ${APPLICATION}"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/mmdl.service
[Unit]
Description=${APPLICATION} Service
After=network.target mysql.service

[Service]
WorkingDirectory=/opt/mmdl
EnvironmentFile=/opt/mmdl/.env
ExecStart=/usr/bin/npm run start
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mmdl
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f ~/v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
