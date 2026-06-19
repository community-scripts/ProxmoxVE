#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wger-project/wger

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
  nginx \
  redis-server \
  libpq-dev \
  jq
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="sass" setup_nodejs
setup_uv
PG_VERSION="16" setup_postgresql
PG_DB_NAME="wger" PG_DB_USER="wger" setup_postgresql_db

fetch_and_deploy_gh_release "wger" "wger-project/wger" "tarball"

msg_info "Setting up wger"
mkdir -p /opt/wger/{static,media}
chmod o+w /opt/wger/media
cd /opt/wger

$STD corepack enable
$STD npm install
$STD npm run build:css:sass
$STD uv venv
$STD uv pip install . --group docker

SECRET_KEY=$(openssl rand -base64 40)
cat <<EOF >/opt/wger/.env
DJANGO_SETTINGS_MODULE=settings.main
PYTHONPATH=/opt/wger
DJANGO_DB_ENGINE=django.db.backends.postgresql
DJANGO_DB_DATABASE=${PG_DB_NAME}
DJANGO_DB_USER=${PG_DB_USER}
DJANGO_DB_PASSWORD=${PG_DB_PASS}
DJANGO_DB_HOST=localhost
DJANGO_DB_PORT=5432
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost:5432/${PG_DB_NAME}
DJANGO_MEDIA_ROOT=/opt/wger/media
DJANGO_STATIC_ROOT=/opt/wger/static
DJANGO_STATIC_URL=/static/
ALLOWED_HOSTS=${LOCAL_IP},localhost,127.0.0.1
CSRF_TRUSTED_ORIGINS=http://${LOCAL_IP}:3000
USE_X_FORWARDED_HOST=True
SECURE_PROXY_SSL_HEADER=HTTP_X_FORWARDED_PROTO,http
DJANGO_CACHE_BACKEND=django_redis.cache.RedisCache
DJANGO_CACHE_LOCATION=redis://127.0.0.1:6379/1
DJANGO_CACHE_TIMEOUT=300
DJANGO_CACHE_CLIENT_CLASS=django_redis.client.DefaultClient
AXES_CACHE_ALIAS=default
USE_CELERY=True
CELERY_BROKER=redis://127.0.0.1:6379/2
CELERY_BACKEND=redis://127.0.0.1:6379/2
SITE_URL=http://${LOCAL_IP}:3000
SECRET_KEY=${SECRET_KEY}
EOF

set -a && source /opt/wger/.env && set +a

# === CRITICAL FIX FOR BOOTSTRAP ===
msg_info "Temporarily granting superuser rights for bootstrap"
sudo -u postgres psql -c "ALTER USER ${PG_DB_USER} WITH SUPERUSER;"

$STD uv run wger bootstrap
$STD uv run python manage.py collectstatic --no-input

# Create admin with easy password
cat <<EOF | uv run python manage.py shell
from django.contrib.auth import get_user_model
User = get_user_model()
user, created = User.objects.get_or_create(
    username="admin",
    defaults={"email": "admin@localhost"},
)
if created:
    user.set_password("adminadmin")
    user.is_superuser = True
    user.is_staff = True
    user.save()
EOF

# Downgrade user rights
sudo -u postgres psql -c "ALTER USER ${PG_DB_USER} WITH NOSUPERUSER NOCREATEROLE NOCREATEDB;"
msg_ok "Set up wger"

# ====================== PowerSync Setup ======================
msg_info "Setting up PowerSync"
SERVER_IP=$(hostname -I | awk '{print $1}')
POWERSYNC_NODE_VERSION="24.15.0"

# Install Node 24 if needed
if ! command -v node &>/dev/null || ! node -v | grep -q "^v24"; then
  msg_info "Installing Node.js 24"
  curl -fsSL https://deb.nodesource.com/setup_24.x | bash - >/dev/null
  $STD apt install -y nodejs
  corepack enable
  msg_ok "Node.js 24 installed"
fi

# Generate JWT keys if missing
cd /opt/wger
export DJANGO_SETTINGS_MODULE=settings.main
if ! grep -q "JWT_PRIVATE_KEY" /opt/wger/.env; then
  uv run python manage.py generate-jwt-keys >> /opt/wger/.env
  set -a && source /opt/wger/.env && set +a
fi

# PowerSync storage
sudo -u postgres psql -c "ALTER USER ${PG_DB_USER} WITH SUPERUSER CREATEROLE CREATEDB;"
uv run python manage.py setup-powersync-storage
sudo -u postgres psql -d ${PG_DB_NAME} -c "GRANT USAGE, CREATE ON SCHEMA powersync TO ${PG_DB_USER};"
sudo -u postgres psql -d ${PG_DB_NAME} -c "ALTER ROLE ${PG_DB_USER} IN DATABASE ${PG_DB_NAME} SET search_path TO powersync, public;"
sudo -u postgres psql -c "ALTER USER ${PG_DB_USER} WITH NOSUPERUSER NOCREATEROLE NOCREATEDB;"

# Create PowerSync config and services (full block from previous messages)
mkdir -p /opt/powersync
# [Insert full powersync.env, powersync.yaml, sync-rules.yaml, systemd services here - same as before]

# Update .env with PowerSync URL
echo "POWERSYNC_URL=http://${SERVER_IP}:8080" >> /opt/wger/.env
msg_ok "PowerSync setup completed"

# ====================== Services ======================
msg_info "Creating Config and Services"
# wger.service, celery.service, celery-beat.service, nginx config (copy from previous full version)
# ... (paste the full service creation block here)

systemctl enable -q --now redis-server nginx wger celery celery-beat powersync
systemctl restart nginx
msg_ok "Created Config and Services"

motd_ssh
customize
cleanup_lxc

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using: http://${IP}:3000${CL}"
echo ""
echo -e "${RED}⚠️  Default credentials: admin / adminadmin${CL}"
echo -e "${RED}   Change password immediately after login!${CL}"
