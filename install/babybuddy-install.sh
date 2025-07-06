#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/babybuddy/babybuddy

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  uwsgi \
  uwsgi-plugin-python3 \
  libopenjp2-7-dev \
  libpq-dev \
  nginx \
  python3
msg_ok "Installed Dependencies"

setup_uv
fetch_and_deploy_gh_release "babybuddy" "babybuddy/babybuddy"

msg_info "Installing Babybuddy"
mkdir -p /opt/data
cd /opt/babybuddy
$STD uv venv .venv
$STD source .venv/bin/activate
$STD uv pip install -r requirements.txt
cp babybuddy/settings/production.example.py babybuddy/settings/production.py
SECRET_KEY=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)
ALLOWED_HOSTS=$(hostname -I | tr ' ' ',' | sed 's/,$//')",127.0.0.1,localhost"
sed -i \
  -e "s/^SECRET_KEY = \"\"/SECRET_KEY = \"$SECRET_KEY\"/" \
  -e "s/^ALLOWED_HOSTS = \[\"\"\]/ALLOWED_HOSTS = \[$(echo \"$ALLOWED_HOSTS\" | sed 's/,/\",\"/g')\]/" \
  babybuddy/settings/production.py

export DJANGO_SETTINGS_MODULE=babybuddy.settings.production
$STD python manage.py migrate
chown -R www-data:www-data /opt/data
chmod 640 /opt/data/db.sqlite3
chmod 750 /opt/data
msg_ok "Installed Babybuddy"

msg_info "Configuring uWSGI"
cat <<EOF >/etc/uwsgi/apps-available/babybuddy.ini
[uwsgi]
plugins = python3
project = babybuddy
base_dir = /opt/babybuddy
chdir = %(base_dir)
virtualenv = %(base_dir)/.venv
module = %(project).wsgi:application
env = DJANGO_SETTINGS_MODULE=%(project).settings.production
master = True
vacuum = True
socket = /var/run/uwsgi/app/babybuddy/socket
chmod-socket = 660
uid = www-data
gid = www-data
EOF
ln -sf /etc/uwsgi/apps-available/babybuddy.ini /etc/uwsgi/apps-enabled/babybuddy.ini
service uwsgi restart
msg_ok "Configured uWSGI"

msg_info "Configuring NGINX"
cat <<EOF >/etc/nginx/sites-available/babybuddy
upstream babybuddy {
    server unix:///var/run/uwsgi/app/babybuddy/socket;
}

server {
    listen 80;
    server_name _;

    location / {
        uwsgi_pass babybuddy;
        include uwsgi_params;
    }

    location /media {
        alias /opt/data/media;
    }
}
EOF

ln -sf /etc/nginx/sites-available/babybuddy /etc/nginx/sites-enabled/babybuddy
rm /etc/nginx/sites-enabled/default
systemctl enable -q --now nginx
service nginx reload
msg_ok "Configured NGINX"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
