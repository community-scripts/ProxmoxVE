#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sassanix/Warracker/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
    build-essential \
    libpq-dev \
    nginx
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv
PG_VERSION="17" setup_postgresql

msg_info "Setup PostgreSQL"
DB_NAME="warranty_db"
DB_USER="warranty_user"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
DB_ADMIN_USER="warracker_admin"
DB_ADMIN_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE USER $DB_ADMIN_USER WITH PASSWORD '$DB_ADMIN_PASS' SUPERUSER;"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_ADMIN_USER;"
$STD sudo -u postgres psql -d "$DB_NAME" -c "GRANT USAGE ON SCHEMA public TO $DB_USER;"
$STD sudo -u postgres psql -d "$DB_NAME" -c "GRANT CREATE ON SCHEMA public TO $DB_USER;"
$STD sudo -u postgres psql -d "$DB_NAME" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO $DB_USER;"
{
    echo "Application Credentials"
    echo "DB_NAME: $DB_NAME"
    echo "DB_USER: $DB_USER"
    echo "DB_PASS: $DB_PASS"
    echo "DB_ADMIN_USER: $DB_ADMIN_USER"
    echo "DB_ADMIN_PASS: $DB_ADMIN_PASS"
} >>~/warracker.creds
msg_ok "Setup PostgreSQL"

fetch_and_deploy_gh_release "warracker" "sassanix/Warracker" "tarball" "latest" "/opt/warracker"

msg_info "Installing Warracker"
cd /opt/warracker/backend
$STD uv venv .venv
$STD source .venv/bin/activate
$STD uv pip install -r requirements.txt
mv /opt/warracker/env.example /opt/.env
sed -i \
    -e "s/your_secure_database_password/$DB_PASS/" \
    -e "s/your_secure_admin_password/$DB_ADMIN_PASS/" \
    -e "s|^# DB_PORT=5432$|DB_HOST=127.0.0.1|" \
    -e "s|your_very_secure_flask_secret_key_change_this_in_production|$(openssl rand -base64 32 | tr -d '\n')|" \
    /opt/.env
mkdir -p /data/uploads
msg_ok "Installed Warracker"

msg_info "Configuring Nginx"
mv /opt/warracker/nginx.conf /etc/nginx/sites-available/warracker.conf
sed -i \
    -e "s|alias /var/www/html/locales/;|alias /opt/warracker/locales/;|" \
    -e "s|/var/www/html|/opt/warracker/frontend|g" \
    -e "s/client_max_body_size __NGINX_MAX_BODY_SIZE_CONFIG_VALUE__/client_max_body_size 32M/" \
    /etc/nginx/sites-available/warracker.conf
ln -s /etc/nginx/sites-available/warracker.conf /etc/nginx/sites-enabled/warracker.conf
rm /etc/nginx/sites-enabled/default
systemctl restart nginx

msg_ok "Configured Nginx"

msg_info "Creating systemd services"
cat <<EOF >/etc/systemd/system/warrackermigration.service
[Unit]
Description=Warracker Migration Service
After=network.target

[Service]
Type=oneshot
WorkingDirectory=/opt/warracker/backend/migrations
EnvironmentFile=/opt/.env
ExecStart=/opt/warracker/backend/.venv/bin/python apply_migrations.py

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/warracker.service
[Unit]
Description=Warracker Service
After=network.target warrackermigration.service
Requires=warrackermigration.service

[Service]
WorkingDirectory=/opt/warracker
EnvironmentFile=/opt/.env
ExecStart=/opt/warracker/backend/.venv/bin/gunicorn --config /opt/warracker/backend/gunicorn_config.py backend:create_app() --bind 127.0.0.1:5000
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now warracker
msg_ok "Started Warracker Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
