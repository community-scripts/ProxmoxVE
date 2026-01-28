#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://netboxlabs.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  apache2 \
  redis-server \
  build-essential \
  libxml2-dev \
  libxslt1-dev \
  libffi-dev \
  libpq-dev \
  libssl-dev \
  zlib1g-dev
msg_ok "Installed Dependencies"

PG_VERSION="16" setup_postgresql
PG_DB_NAME="netbox" PG_DB_USER="netbox" setup_postgresql_db

msg_info "Installing Python"
$STD apt install -y \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev
msg_ok "Installed Python"

fetch_and_deploy_gh_release "netbox" "netbox-community/netbox" "tarball"

msg_info "Configuring NetBox (Patience)"
cd /opt/netbox
mkdir -p /opt/netbox/netbox/media

$STD adduser --system --group netbox
chown -R netbox /opt/netbox/netbox

mv /opt/netbox/netbox/netbox/configuration_example.py /opt/netbox/netbox/netbox/configuration.py

SECRET_KEY=$(python3 /opt/netbox/netbox/generate_secret_key.py)
ESCAPED_SECRET_KEY=$(printf '%s\n' "$SECRET_KEY" | sed 's/[&/\]/\\&/g')

sed -i -e 's/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = ["*"]/' \
  -e "s|SECRET_KEY = ''|SECRET_KEY = '${ESCAPED_SECRET_KEY}'|" \
  -e "/DATABASES = {/,/}/s/'USER': '[^']*'/'USER': '$PG_DB_USER'/" \
  -e "/DATABASES = {/,/}/s/'PASSWORD': '[^']*'/'PASSWORD': '$PG_DB_PASS'/" /opt/netbox/netbox/netbox/configuration.py

$STD /opt/netbox/upgrade.sh
ln -s /opt/netbox/contrib/netbox-housekeeping.sh /etc/cron.daily/netbox-housekeeping

mv /opt/netbox/contrib/apache.conf /etc/apache2/sites-available/netbox.conf
$STD openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/netbox.key -out /etc/ssl/certs/netbox.crt -subj "/C=US/O=NetBox/OU=Certificate/CN=localhost"
$STD a2enmod ssl proxy proxy_http headers rewrite
$STD a2ensite netbox
systemctl restart apache2

mv /opt/netbox/contrib/gunicorn.py /opt/netbox/gunicorn.py
mv /opt/netbox/contrib/*.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable -q --now netbox netbox-rq
echo -e "Netbox Secret: \e[32m$SECRET_KEY\e[0m" >>~/netbox.creds
msg_ok "Configured NetBox"

msg_info "Setting up Django Admin"
DJANGO_USER=Admin
DJANGO_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)

source /opt/netbox/venv/bin/activate
$STD python3 /opt/netbox/netbox/manage.py shell <<EOF
from django.contrib.auth import get_user_model
UserModel = get_user_model()
user = UserModel.objects.create_user('$DJANGO_USER', password='$DJANGO_PASS')
user.is_superuser = True
user.is_staff = True
user.save()
EOF
{
  echo ""
  echo "Netbox-Django-Credentials"
  echo -e "Django User: \e[32m$DJANGO_USER\e[0m"
  echo -e "Django Password: \e[32m$DJANGO_PASS\e[0m"
} >>~/netbox.creds
msg_ok "Setup Django Admin"

motd_ssh
customize
cleanup_lxc
