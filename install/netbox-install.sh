#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: bvdberg01
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get update
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y apache2
$STD apt-get install -y redis-server
$STD apt-get install -y postgresql
$STD apt-get install -y python3
$STD apt-get install -y python3-pip
$STD apt-get install -y python3-venv
$STD apt-get install -y python3-dev
$STD apt-get install -y build-essential
$STD apt-get install -y libxml2-dev
$STD apt-get install -y libxslt1-dev
$STD apt-get install -y libffi-dev
$STD apt-get install -y libpq-dev
$STD apt-get install -y libssl-dev
$STD apt-get install -y zlib1g-dev
msg_ok "Installed Dependencies"

msg_info "Setting up PostgreSQL"
DB_NAME=netbox
DB_USER=netbox
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0;"
msg_ok "Set up PostgreSQL"

msg_info "Installing NetBox"        
RELEASE=$(curl -s https://api.github.com/repos/netbox-community/netbox/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/netbox-community/netbox/archive/refs/tags/v${RELEASE}.tar.gz"
tar -xzf "v${RELEASE}.tar.gz" -C /opt
ln -s "/opt/netbox-${RELEASE}/" /opt/netbox
rm "v${RELEASE}.tar.gz"

$STD adduser --system --group netbox
chown --recursive netbox /opt/netbox/netbox/media/
chown --recursive netbox /opt/netbox/netbox/reports/
chown --recursive netbox /opt/netbox/netbox/scripts/

cp /opt/netbox/netbox/netbox/configuration_example.py /opt/netbox/netbox/netbox/configuration.py

secret=$(python3 /opt/netbox/netbox/generate_secret_key.py)
escaped_secret=$(printf '%s\n' "$secret" | sed 's/[&/\]/\\&/g')

sed -i 's/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = ["*"]/' /opt/netbox/netbox/netbox/configuration.py
sed -i "s|SECRET_KEY = ''|SECRET_KEY = '${escaped_secret}'|" /opt/netbox/netbox/netbox/configuration.py
sed -i "/DATABASE = {/,/}/s/'USER': '[^']*'/'USER': '$DB_USER'/" /opt/netbox/netbox/netbox/configuration.py
sed -i "/DATABASE = {/,/}/s/'PASSWORD': '[^']*'/'PASSWORD': '$DB_PASS'/" /opt/netbox/netbox/netbox/configuration.py

$STD /opt/netbox/upgrade.sh &>/dev/null
sudo ln -s /opt/netbox/contrib/netbox-housekeeping.sh /etc/cron.daily/netbox-housekeeping

sudo cp /opt/netbox/contrib/apache.conf /etc/apache2/sites-available/netbox.conf
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/netbox.key -out /etc/ssl/certs/netbox.crt -subj "/C=US/O=NetBox/OU=Certificate/CN=localhost" &>/dev/null
$STD a2enmod ssl proxy proxy_http headers rewrite
$STD a2ensite netbox
systemctl restart apache2

cp /opt/netbox/contrib/gunicorn.py /opt/netbox/gunicorn.py
cp /opt/netbox/contrib/*.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable -q --now netbox netbox-rq

msg_ok "Installed NetBox"

msg_info "Setting up Django Admin"
NetBox_USER=Admin
NetBox_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)

source /opt/netbox/venv/bin/activate
$STD python3 /opt/netbox/netbox/manage.py shell << EOF
from django.contrib.auth import get_user_model
UserModel = get_user_model()
user = UserModel.objects.create_user('$NetBox_USER', password='$NetBox_PASS')
user.is_superuser = True
user.is_staff = True
user.save()
EOF
msg_ok "Setup Django Admin"

msg_info "Save credential file"
echo "" >~/NetBox.creds
echo "NetBox Database Credentials" >>~/NetBox.creds
echo "" >>~/NetBox.creds
echo -e "NetBox Database User: \e[32m$DB_USER\e[0m" >>~/NetBox.creds
echo -e "NetBox Database Password: \e[32m$DB_PASS\e[0m" >>~/NetBox.creds
echo -e "NetBox Database Name: \e[32m$DB_NAME\e[0m" >>~/NetBox.creds
echo -e "NetBox Admin user: \e[32m$NetBox_USER\e[0m" >>~/NetBox.creds
echo -e "NetBox Admin Password: \e[32m$NetBox_PASS\e[0m" >>~/NetBox.creds
msg_ok "Save cred file"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
