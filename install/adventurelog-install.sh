#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/seanmorley15/AdventureLog

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  gdal-bin \
  libgdal-dev \
  git \
  memcached \
  libmemcached-tools
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.13" setup_uv
NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs
PG_VERSION="17" PG_MODULES="postgis" setup_postgresql
PG_DB_NAME="adventurelog_db" PG_DB_USER="adventurelog_user" PG_DB_EXTENSIONS="postgis" setup_postgresql_db
fetch_and_deploy_gh_release "adventurelog" "seanmorley15/adventurelog" "tarball"
import_local_ip

msg_info "Installing AdventureLog (Patience)"
SECRET_KEY="$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | cut -c1-32)"
echo "AdventureLog Secret: $SECRET_KEY" >>~/adventurelog.creds
DJANGO_ADMIN_USER="djangoadmin"
DJANGO_ADMIN_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
cat <<EOF >/opt/adventurelog/backend/server/.env
PGHOST='localhost'
PGDATABASE='${PG_DB_NAME}'
PGUSER='${PG_DB_USER}'
PGPASSWORD='${PG_DB_PASS}'
SECRET_KEY='${SECRET_KEY}'
PUBLIC_URL='http://$LOCAL_IP:8000'
DEBUG=True
FRONTEND_URL='http://$LOCAL_IP:3000'
CSRF_TRUSTED_ORIGINS='http://127.0.0.1:3000,http://localhost:3000,http://$LOCAL_IP:3000'
DJANGO_ADMIN_USERNAME='${DJANGO_ADMIN_USER}'
DJANGO_ADMIN_PASSWORD='${DJANGO_ADMIN_PASS}'
DISABLE_REGISTRATION=False
# EMAIL_BACKEND='email'
# EMAIL_HOST='smtp.gmail.com'
# EMAIL_USE_TLS=False
# EMAIL_PORT=587
# EMAIL_USE_SSL=True
# EMAIL_HOST_USER='user'
# EMAIL_HOST_PASSWORD='password'
# DEFAULT_FROM_EMAIL='user@example.com'
EOF
cd /opt/adventurelog/backend/server
mkdir -p /opt/adventurelog/backend/server/media
$STD uv venv /opt/adventurelog/backend/server/.venv
$STD /opt/adventurelog/backend/server/.venv/bin/python -m ensurepip --upgrade
$STD /opt/adventurelog/backend/server/.venv/bin/python -m pip install --upgrade pip
$STD /opt/adventurelog/backend/server/.venv/bin/python -m pip install -r requirements.txt
$STD /opt/adventurelog/backend/server/.venv/bin/python -m manage collectstatic --noinput
$STD /opt/adventurelog/backend/server/.venv/bin/python -m manage migrate
$STD /opt/adventurelog/backend/server/.venv/bin/python -m manage download-countries
cat <<EOF >/opt/adventurelog/frontend/.env
PUBLIC_SERVER_URL=http://$LOCAL_IP:8000
BODY_SIZE_LIMIT=Infinity
ORIGIN='http://$LOCAL_IP:3000'
EOF
cd /opt/adventurelog/frontend
$STD pnpm i
$STD pnpm build
msg_ok "Installed AdventureLog"

msg_info "Setting up Django Admin"
cd /opt/adventurelog/backend/server
$STD .venv/bin/python -m manage shell <<EOF
from django.contrib.auth import get_user_model
UserModel = get_user_model()
user = UserModel.objects.create_user('$DJANGO_ADMIN_USER', password='$DJANGO_ADMIN_PASS')
user.is_superuser = True
user.is_staff = True
user.save()
EOF
{
  echo ""
  echo "Django-Credentials"
  echo "Django Admin User: $DJANGO_ADMIN_USER"
  echo "Django Admin Password: $DJANGO_ADMIN_PASS"
} >>~/adventurelog.creds
msg_ok "Setup Django Admin"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/adventurelog-backend.service
[Unit]
Description=AdventureLog Backend Service
After=network.target postgresql.service

[Service]
WorkingDirectory=/opt/adventurelog/backend/server
ExecStart=/opt/adventurelog/backend/server/.venv/bin/python -m manage runserver 0.0.0.0:8000
Restart=always
EnvironmentFile=/opt/adventurelog/backend/server/.env

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/adventurelog-frontend.service
[Unit]
Description=AdventureLog SvelteKit Frontend Service
After=network.target

[Service]
WorkingDirectory=/opt/adventurelog/frontend
ExecStart=/usr/bin/node build 127.0.0.1:3000
Restart=always
EnvironmentFile=/opt/adventurelog/frontend/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now adventurelog-backend
systemctl enable -q --now adventurelog-frontend
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
