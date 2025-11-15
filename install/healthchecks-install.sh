#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://healthchecks.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  gcc \
  libpq-dev \
  libcurl4-openssl-dev \
  libssl-dev \
  caddy
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.13" setup_uv
PG_VERSION=16 setup_postgresql

msg_info "Setup Database"
DB_NAME=healthchecks_db
DB_USER=hc_user
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
SECRET_KEY="$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)"
ADMIN_EMAIL="admin@helper-scripts.local"
ADMIN_PASSWORD="$DB_PASS"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC'"
{
  echo "healthchecks-Credentials"
  echo "healthchecks Database User: $DB_USER"
  echo "healthchecks Database Password: $DB_PASS"
  echo "healthchecks Database Name: $DB_NAME"
  echo "healthchecks Admin Email: $ADMIN_EMAIL"
  echo "healthchecks Admin Password: $ADMIN_PASSWORD"
} >>~/healthchecks.creds
msg_ok "Set up Database"

fetch_and_deploy_gh_release "healthchecks" "healthchecks/healthchecks"

msg_info "Setup healthchecks"
cd /opt/healthchecks
mkdir -p /opt/healthchecks/static-collected/
$STD uv pip install wheel gunicorn -r requirements.txt --system

LOCAL_IP=$(hostname -I | awk '{print $1}')
cat <<EOF >/opt/healthchecks/hc/local_settings.py
DEBUG = False

ALLOWED_HOSTS = ["${LOCAL_IP}", "127.0.0.1", "localhost"]
CSRF_TRUSTED_ORIGINS = ["http://${LOCAL_IP}", "https://${LOCAL_IP}"]

SECRET_KEY = "${SECRET_KEY}"

SITE_ROOT = "http://${LOCAL_IP}:8000"
SITE_NAME = "MyChecks"
DEFAULT_FROM_EMAIL = "healthchecks@${LOCAL_IP}"

STATIC_ROOT = "/opt/healthchecks/static-collected"
COMPRESS_OFFLINE = True

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': '${DB_NAME}',
        'USER': '${DB_USER}',
        'PASSWORD': '${DB_PASS}',
        'HOST': '127.0.0.1',
        'PORT': '5432',
        'TEST': {'CHARSET': 'UTF8'}
    }
}
EOF

$STD uv run -- python manage.py makemigrations
$STD uv run -- python manage.py migrate --noinput
$STD uv run -- python manage.py collectstatic --noinput
$STD uv run -- python manage.py compress

cat <<EOF | $STD uv run -- python manage.py shell
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(email="${ADMIN_EMAIL}").exists():
    User.objects.create_superuser("${ADMIN_EMAIL}", "${ADMIN_EMAIL}", "${ADMIN_PASSWORD}")
EOF
msg_ok "Installed healthchecks"

msg_info "Configuring Caddy"
cat <<EOF >/etc/caddy/Caddyfile
{
    email admin@example.com
}

${LOCAL_IP} {
    reverse_proxy 127.0.0.1:8000
}
EOF
msg_ok "Configured Caddy"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/healthchecks.service
[Unit]
Description=Healthchecks Service
After=network.target postgresql.service

[Service]
WorkingDirectory=/opt/healthchecks/
ExecStart=/usr/local/bin/uv run -- gunicorn hc.wsgi:application --bind 127.0.0.1:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now healthchecks caddy
systemctl reload caddy
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
