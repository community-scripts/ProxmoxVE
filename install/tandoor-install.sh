#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tandoor.dev/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt install -y \
  build-essential \
  python3 \
  libpq-dev \
  libmagic-dev \
  libzbar0 \
  nginx \
  libsasl2-dev \
  libldap2-dev \
  libssl-dev \
  pkg-config \
  libxmlsec1-dev \
  libxml2-dev \
  libxmlsec1-openssl
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs
fetch_and_deploy_gh_release "tandoor" "TandoorRecipes/recipes" "tarball" "latest" "/opt/tandoor"
PG_VERSION="17" setup_postgresql
PYTHON_VERSION="3.13" setup_uv
PG_DB_USER="tandoor" PG_DB_NAME="db_recipes" PG_DB_EXTENSIONS="unaccent,pg_trgm" setup_postgresql_db
SECRET_KEY=$(openssl rand -base64 45 | sed 's/\//\\\//g')

msg_info "Setup Tandoor"
mkdir -p /opt/tandoor/{config,api,mediafiles,staticfiles}
cd /opt/tandoor
$STD uv venv .venv --python=python3
$STD uv pip install -r requirements.txt --python .venv/bin/python
cd /opt/tandoor/vue3
$STD yarn install
$STD yarn build
cat <<EOF >/opt/tandoor/.env
SECRET_KEY=$SECRET_KEY
TZ=Europe/Berlin

DB_ENGINE=django.db.backends.postgresql
POSTGRES_HOST=localhost
POSTGRES_DB=$PG_DB_NAME
POSTGRES_PORT=5432
POSTGRES_USER=$PG_DB_USER
POSTGRES_PASSWORD=$PG_DB_PASS

STATIC_URL=/staticfiles/
MEDIA_URL=/media/
EOF

TANDOOR_VERSION=$(get_latest_github_release "TandoorRecipes/recipes")
cat <<EOF >/opt/tandoor/cookbook/version_info.py
TANDOOR_VERSION = "$TANDOOR_VERSION"
TANDOOR_REF = "bare-metal"
VERSION_INFO = []
EOF

cd /opt/tandoor
$STD /opt/tandoor/.venv/bin/python manage.py migrate
$STD /opt/tandoor/.venv/bin/python manage.py collectstatic --no-input
msg_ok "Installed Tandoor"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/tandoor.service
[Unit]
Description=gunicorn daemon for tandoor
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=3
WorkingDirectory=/opt/tandoor
EnvironmentFile=/opt/tandoor/.env
ExecStart=/opt/tandoor/.venv/bin/gunicorn --error-logfile /tmp/gunicorn_err.log --log-level debug --capture-output --bind unix:/opt/tandoor/tandoor.sock recipes.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

cat <<'EOF' >/etc/nginx/conf.d/tandoor.conf
server {
    listen 8002;
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    client_max_body_size 128M;
    # serve media files
    location /static/ {
        alias /opt/tandoor/staticfiles/;
    }

    location /media/ {
        alias /opt/tandoor/mediafiles/;
    }

    location / {
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
        proxy_pass http://unix:/opt/tandoor/tandoor.sock;
    }
}
EOF
systemctl reload nginx
systemctl enable -q --now tandoor
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
