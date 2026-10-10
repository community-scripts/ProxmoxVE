#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/WeblateOrg/weblate

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
  pkg-config \
  libacl1-dev \
  liblz4-dev \
  libzstd-dev \
  libxxhash-dev \
  libssl-dev \
  libldap2-dev \
  libsasl2-dev \
  git \
  gettext \
  nginx \
  valkey-server
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
PG_DB_NAME="weblate" PG_DB_USER="weblate" setup_postgresql_db
PYTHON_VERSION="3.14" setup_uv
USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "weblate" "WeblateOrg/weblate" "singlefile" "latest" "/opt/weblate" "weblate-*-py3-none-any.whl"

msg_info "Installing Weblate"
$STD uv venv --python 3.14 /opt/weblate/.venv
$STD uv pip install --python /opt/weblate/.venv/bin/python --compile-bytecode /opt/weblate/weblate-*.whl "weblate[all,wsgi]"
rm -f /opt/weblate/weblate-*.whl
msg_ok "Installed Weblate"

msg_info "Configuring Weblate"
mkdir -p /opt/weblate_data/python/customize /app
# weblate.settings_docker is upstream's env-driven settings; it reads the secret and
# settings-override.py from /app/data and loads the "customize" app from DATA_DIR/python
ln -sfn /opt/weblate_data /app/data
touch /opt/weblate_data/python/customize/{__init__,models}.py
/opt/weblate/.venv/bin/weblate-generate-secret-key >/opt/weblate_data/secret
cat <<EOF >/opt/weblate_data/weblate.env
DJANGO_SETTINGS_MODULE=weblate.settings_docker
PYTHONPATH=/opt/weblate_data/python
WEBLATE_SITE_DOMAIN=${LOCAL_IP}
WEBLATE_DATA_DIR=/opt/weblate_data
WEBLATE_CACHE_DIR=/opt/weblate/cache
WEBLATE_IP_PROXY_HEADER=HTTP_X_FORWARDED_FOR
POSTGRES_HOST=127.0.0.1
POSTGRES_DB=weblate
POSTGRES_USER=weblate
POSTGRES_PASSWORD=${PG_DB_PASS}
REDIS_HOST=127.0.0.1
# Password set for the "admin" account at install; Weblate does not read it
WEBLATE_ADMIN_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)
EOF
chmod 600 /opt/weblate_data/secret /opt/weblate_data/weblate.env
set -a
source /opt/weblate_data/weblate.env
set +a
$STD /opt/weblate/.venv/bin/weblate migrate --noinput
$STD /opt/weblate/.venv/bin/weblate createadmin --password="${WEBLATE_ADMIN_PASSWORD}"
$STD /opt/weblate/.venv/bin/weblate collectstatic --noinput
msg_ok "Configured Weblate"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/weblate
server {
    listen 80;
    server_name _;
    client_max_body_size 1000M;

    location = /favicon.ico {
        alias /opt/weblate/cache/static/favicon.ico;
        expires 30d;
    }

    location /static/ {
        alias /opt/weblate/cache/static/;
        expires 30d;
    }

    location / {
        proxy_pass http://127.0.0.1:8888;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 3600;
    }
}
EOF
nginx_enable_site "weblate"
msg_ok "Configured Nginx"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/weblate.service
[Unit]
Description=Weblate
After=network.target postgresql.service valkey-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/weblate_data
EnvironmentFile=/opt/weblate_data/weblate.env
ExecStart=/opt/weblate/.venv/bin/granian --interface wsgi --host 127.0.0.1 --port 8888 --workers 2 --blocking-threads 8 --backlog 128 --backpressure 16 --runtime-mode mt --workers-max-rss 450 --no-ws weblate.wsgi:application
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF >/etc/systemd/system/weblate-celery.service
[Unit]
Description=Weblate Celery Worker
After=network.target postgresql.service valkey-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/weblate_data
EnvironmentFile=/opt/weblate_data/weblate.env
ExecStart=/opt/weblate/.venv/bin/celery --app=weblate.utils worker --beat --loglevel=info --queues=celery,notify,memory,translate,backup --prefetch-multiplier=1 --concurrency=2
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now weblate weblate-celery
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
