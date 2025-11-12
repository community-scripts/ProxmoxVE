#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: ekke85
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Dispatcharr/Dispatcharr

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
  python3-dev \
  libpq-dev \
  nginx \
  redis-server \
  ffmpeg \
  procps \
  streamlink
msg_ok "Installed Dependencies"

setup_uv
NODE_VERSION="24" setup_nodejs
PG_VERSION="16" setup_postgresql

msg_info "Creating PostgreSQL Database"
DB_NAME=dispatcharr_db
DB_USER=dispatcharr_usr
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC';"
{
  echo "Dispatcharr Credentials"
  echo "Database Name: $DB_NAME"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
  echo ""
} >>~/dispatcharr.creds
msg_ok "Created PostgreSQL Database"

fetch_and_deploy_gh_release "dispatcharr" "Dispatcharr/Dispatcharr"

msg_info "Installing Python Dependencies with uv"
cd /opt/dispatcharr
$STD uv venv
$STD uv pip install -r requirements.txt --index-strategy unsafe-best-match
$STD uv pip install gunicorn gevent celery redis daphne
msg_ok "Installed Python Dependencies"

msg_info "Configuring Dispatcharr"
install -d -m 755 \
  /data/{logos,recordings,plugins,db} \
  /data/uploads/{m3us,epgs} \
  /data/{m3us,epgs}
chown -R root:root /data
export DATABASE_URL="postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}"
export POSTGRES_DB=$DB_NAME
export POSTGRES_USER=$DB_USER
export POSTGRES_PASSWORD=$DB_PASS
export POSTGRES_HOST=localhost
$STD uv run python manage.py migrate --noinput
$STD uv run python manage.py collectstatic --noinput
cat <<EOF >/opt/dispatcharr/.env
DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}
POSTGRES_DB=$DB_NAME
POSTGRES_USER=$DB_USER
POSTGRES_PASSWORD=$DB_PASS
POSTGRES_HOST=localhost
CELERY_BROKER_URL=redis://localhost:6379/0
EOF
cd /opt/dispatcharr/frontend
$STD npm install --legacy-peer-deps
$STD npm run build
msg_ok "Configured Dispatcharr"

msg_info "Configuring Nginx"
cat <<EOF >/etc/nginx/sites-available/dispatcharr.conf
server {
    listen 80;
    server_name _;

    # Serve static assets with correct MIME types
    location /assets/ {
        alias /opt/dispatcharr/frontend/dist/assets/;
        expires 30d;
        add_header Cache-Control "public, immutable";

        # Explicitly set MIME types for webpack-built assets
        types {
            text/javascript js;
            text/css css;
            image/png png;
            image/svg+xml svg svgz;
            font/woff2 woff2;
            font/woff woff;
            font/ttf ttf;
        }
    }

    location /static/ {
        alias /opt/dispatcharr/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias /opt/dispatcharr/media/;
    }

    location /ws/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # All other requests proxy to Gunicorn
    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:5656;
    }
}
EOF
ln -sf /etc/nginx/sites-available/dispatcharr.conf /etc/nginx/sites-enabled/dispatcharr.conf
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx
msg_ok "Configured Nginx"

msg_info "Creating Services"
cat <<EOF >/opt/dispatcharr/start-gunicorn.sh
#!/usr/bin/env bash
cd /opt/dispatcharr
set -a
source .env
set +a
exec uv run gunicorn \\
    --workers=4 \\
    --worker-class=gevent \\
    --timeout=300 \\
    --bind 0.0.0.0:5656 \\
    dispatcharr.wsgi:application
EOF
chmod +x /opt/dispatcharr/start-gunicorn.sh

cat <<EOF >/opt/dispatcharr/start-celery.sh
#!/usr/bin/env bash
cd /opt/dispatcharr
set -a
source .env
set +a
exec uv run celery -A dispatcharr worker -l info -c 4
EOF
chmod +x /opt/dispatcharr/start-celery.sh

cat <<EOF >/opt/dispatcharr/start-celerybeat.sh
#!/usr/bin/env bash
cd /opt/dispatcharr
set -a
source .env
set +a
exec uv run celery -A dispatcharr beat -l info
EOF
chmod +x /opt/dispatcharr/start-celerybeat.sh

cat <<EOF >/opt/dispatcharr/start-daphne.sh
#!/usr/bin/env bash
cd /opt/dispatcharr
set -a
source .env
set +a
exec uv run daphne -b 0.0.0.0 -p 8001 dispatcharr.asgi:application
EOF
chmod +x /opt/dispatcharr/start-daphne.sh

cat <<EOF >/etc/systemd/system/dispatcharr.service
[Unit]
Description=Dispatcharr Web Server
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/dispatcharr
ExecStart=/opt/dispatcharr/start-gunicorn.sh
Restart=on-failure
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/dispatcharr-celery.service
[Unit]
Description=Dispatcharr Celery Worker
After=network.target redis-server.service
Requires=dispatcharr.service

[Service]
Type=simple
WorkingDirectory=/opt/dispatcharr
ExecStart=/opt/dispatcharr/start-celery.sh
Restart=on-failure
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/dispatcharr-celerybeat.service
[Unit]
Description=Dispatcharr Celery Beat Scheduler
After=network.target redis-server.service
Requires=dispatcharr.service

[Service]
Type=simple
WorkingDirectory=/opt/dispatcharr
ExecStart=/opt/dispatcharr/start-celerybeat.sh
Restart=on-failure
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/dispatcharr-daphne.service
[Unit]
Description=Dispatcharr WebSocket Server (Daphne)
After=network.target
Requires=dispatcharr.service

[Service]
Type=simple
WorkingDirectory=/opt/dispatcharr
ExecStart=/opt/dispatcharr/start-daphne.sh
Restart=on-failure
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now dispatcharr dispatcharr-celery dispatcharr-celerybeat dispatcharr-daphne
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
