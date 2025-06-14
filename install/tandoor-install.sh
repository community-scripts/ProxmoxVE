#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
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
$STD apt-get install -y \
  build-essential \
  libpq-dev \
  libmagic-dev \
  libzbar0 \
  nginx \
  libsasl2-dev \
  libldap2-dev \
  libssl-dev \
  git \
  make \
  pkg-config \
  libxmlsec1-dev \
  libxml2-dev \
  libxmlsec1-openssl
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv
NODE_VERSION="20" NODE_MODULE="yarn@latest" install_node_and_modules

msg_info "Installing Tandoor (Patience)"
$STD git clone https://github.com/TandoorRecipes/recipes -b master /opt/tandoor
mkdir -p /opt/tandoor/{config,api,mediafiles,staticfiles}
cd /opt/tandoor
$STD uv venv /opt/tandoor/.venv
$STD /opt/tandoor/.venv/bin/python -m ensurepip --upgrade
$STD /opt/tandoor/.venv/bin/python -m pip install --upgrade pip
$STD /opt/tandoor/.venv/bin/python -m pip install -r requirements.txt

cd /opt/tandoor/vue
$STD yarn install
$STD yarn build

curl -fsSL "https://raw.githubusercontent.com/TandoorRecipes/recipes/develop/.env.template" -o "/opt/tandoor/.env"
DB_NAME=db_recipes
DB_USER=tandoor
DB_ENCODING=utf8
DB_TIMEZONE=UTC
secret_key=$(openssl rand -base64 45 | sed 's/\//\\\//g')
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
sed -i -e "s|SECRET_KEY=.*|SECRET_KEY=$secret_key|g" \
  -e "s|POSTGRES_HOST=.*|POSTGRES_HOST=localhost|g" \
  -e "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$DB_PASS|g" \
  -e "s|POSTGRES_DB=.*|POSTGRES_DB=$DB_NAME|g" \
  -e "s|POSTGRES_USER=.*|POSTGRES_USER=$DB_USER|g" \
  -e "\$a\STATIC_URL=/staticfiles/" /opt/tandoor/.env
cd /opt/tandoor
$STD /opt/tandoor/.venv/bin/python -m version.py
msg_ok "Installed Tandoor"

msg_info "Install/Set up PostgreSQL Database"
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
echo "deb https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" >/etc/apt/sources.list.d/pgdg.list
$STD apt-get update
$STD apt-get install -y postgresql-16
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC'"
echo "" >>~/tandoor.creds
echo -e "Tandoor Database Name: \e[32m$DB_NAME\e[0m" >>~/tandoor.creds
echo -e "Tandoor Database User: \e[32m$DB_USER\e[0m" >>~/tandoor.creds
echo -e "Tandoor Database Password: \e[32m$DB_PASS\e[0m" >>~/tandoor.creds
export $(cat /opt/tandoor/.env | grep "^[^#]" | xargs)
$STD /opt/tandoor/.venv/bin/python -m manage migrate
$STD /opt/tandoor/.venv/bin/python -m manage collectstatic --no-input
$STD /opt/tandoor/.venv/bin/python -m python manage collectstatic_js_reverse
msg_ok "Set up PostgreSQL Database"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/gunicorn_tandoor.service
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
    #access_log /var/log/nginx/access.log;
    #error_log /var/log/nginx/error.log;
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
        proxy_pass http://unix:/opt/tandoor/tandoor.sock;
    }
}
EOF
systemctl reload nginx
systemctl enable -q --now gunicorn_tandoor
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
