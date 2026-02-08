#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
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
  python3 \
  python3-dev \
  python3-venv \
  libpq-dev \
  libcurl4-openssl-dev \
  libssl-dev \
  caddy

mkdir -p ~/.config/pip
cat > ~/.config/pip/pip.conf << EOF
[global]
break-system-packages = true
EOF
msg_ok "Installed Dependencies"

PG_VERSION=16 setup_postgresql
PG_DB_NAME="healthchecks_db" PG_DB_USER="hc_user" PG_DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13) setup_postgresql_db

msg_info "Setup Keys (Admin / Secret)"
SECRET_KEY="$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)"
ADMIN_EMAIL="admin@helper-scripts.local"
ADMIN_PASSWORD="$PG_DB_PASS"
{
  echo "healthchecks Admin Email: $ADMIN_EMAIL"
  echo "healthchecks Admin Password: $ADMIN_PASSWORD"
} >>~/healthchecks.creds
msg_ok "Set up Keys"

fetch_and_deploy_gh_release "healthchecks" "healthchecks/healthchecks" "tarball"

msg_info "Installing Healthchecks (venv)"
cd /opt/healthchecks
python3 -m venv venv
source venv/bin/activate

$STD pip install --upgrade pip wheel
$STD pip install gunicorn -r requirements.txt
msg_ok "Installed Python packages"

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
        'NAME': '${PG_DB_NAME}',
        'USER': '${PG_DB_USER}',
        'PASSWORD': '${PG_DB_PASS}',
        'HOST': '127.0.0.1',
        'PORT': '5432',
        'TEST': {'CHARSET': 'UTF8'}
    }
}
EOF

msg_info "Running Django setup"
$STD python manage.py makemigrations
$STD python manage.py migrate --noinput
$STD python manage.py collectstatic --noinput
$STD python manage.py compress

$STD python manage.py shell <<EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(email="${ADMIN_EMAIL}").exists():
    User.objects.create_superuser("${ADMIN_EMAIL}", "${ADMIN_EMAIL}", "${ADMIN_PASSWORD}")
EOF
msg_ok "Configured Django"

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

msg_info "Creating systemd services"
cat <<EOF >/etc/systemd/system/healthchecks.service
[Unit]
Description=Healthchecks Service
After=network.target postgresql.service

[Service]
WorkingDirectory=/opt/healthchecks/
ExecStart=/opt/healthchecks/venv/bin/gunicorn hc.wsgi:application --bind 127.0.0.1:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/healthchecks-sendalerts.service
[Unit]
Description=Healthchecks Sendalerts Service
After=network.target postgresql.service healthchecks.service

[Service]
WorkingDirectory=/opt/healthchecks/
ExecStart=/opt/healthchecks/venv/bin/python manage.py sendalerts
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now healthchecks healthchecks-sendalerts caddy
systemctl reload caddy
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
