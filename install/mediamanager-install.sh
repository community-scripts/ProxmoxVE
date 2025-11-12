#!/usr/bin/env bash

# Copyright (c) 2025 Community Scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/maxdorninger/MediaManager

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

read -r -p "${TAB3}Enter the email address of your first admin user: " admin_email
if [[ "$admin_email" ]]; then
  EMAIL="$admin_email"
fi

setup_yq
NODE_VERSION="24" setup_nodejs
setup_uv
PG_VERSION="17" setup_postgresql

msg_info "Setting up PostgreSQL"
DB_NAME="mm_db"
DB_USER="mm_user"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
{
  echo "MediaManager Credentials"
  echo "MediaManager Database User: $DB_USER"
  echo "MediaManager Database Password: $DB_PASS"
  echo "MediaManager Database Name: $DB_NAME"
} >>~/mediamanager.creds
msg_ok "Set up PostgreSQL"

fetch_and_deploy_gh_release "MediaManager" "maxdorninger/MediaManager" "tarball" "latest" "/opt/mediamanager"

msg_info "Configuring MediaManager"
MM_DIR="/opt/mm"
MEDIA_DIR="${MM_DIR}/media"
export CONFIG_DIR="${MM_DIR}/config"
export FRONTEND_FILES_DIR="${MM_DIR}/web/build"
export PUBLIC_VERSION=""
export PUBLIC_API_URL=""
export BASE_PATH="/web"
cd /opt/mediamanager/web
$STD npm ci --no-fund --no-audit
$STD npm run build
mkdir -p {"$MM_DIR"/web,"$MEDIA_DIR","$CONFIG_DIR"}
cp -r build "$FRONTEND_FILES_DIR"
export BASE_PATH=""
export VIRTUAL_ENV="${MM_DIR}/venv"
cd /opt/mediamanager
cp -r {media_manager,alembic*} "$MM_DIR"
$STD /usr/local/bin/uv sync --locked --active -n -p cpython3.13 --managed-python
msg_ok "Configured MediaManager"

msg_info "Creating config and start script"
LOCAL_IP="$(hostname -I | awk '{print $1}')"
SECRET="$(openssl rand -hex 32)"
sed -e "s/localhost:8/$LOCAL_IP:8/g" \
  -e "s|/data/|$MEDIA_DIR/|g" \
  -e 's/"db"/"localhost"/' \
  -e "s/user = \"MediaManager\"/user = \"$DB_USER\"/" \
  -e "s/password = \"MediaManager\"/password = \"$DB_PASS\"/" \
  -e "s/dbname = \"MediaManager\"/dbname = \"$DB_NAME\"/" \
  -e "/^token_secret/s/=.*/= \"$SECRET\"/" \
  -e "s/admin@example.com/$EMAIL/" \
  -e '/^admin_emails/s/, .*/]/' \
  /opt/mediamanager/config.example.toml >"$CONFIG_DIR"/config.toml

mkdir -p "$MEDIA_DIR"/{images,tv,movies,torrents}

cat <<EOF >"$MM_DIR"/start.sh
#!/usr/bin/env bash

export CONFIG_DIR="$CONFIG_DIR"
export FRONTEND_FILES_DIR="$FRONTEND_FILES_DIR"
export LOG_FILE="$CONFIG_DIR/media_manager.log"
export BASE_PATH=""
cd $MM_DIR
source ./venv/bin/activate
/usr/local/bin/uv run alembic upgrade head
/usr/local/bin/uv run fastapi run ./media_manager/main.py --port 8000
EOF
chmod +x "$MM_DIR"/start.sh
msg_ok "Created config and start script"

msg_info "Creating service"
cat <<EOF >/etc/systemd/system/mediamanager.service
[Unit]
Description=MediaManager Backend Service
After=network.target

[Service]
Type=simple
WorkingDirectory=${MM_DIR}
ExecStart=/usr/bin/bash start.sh

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now mediamanager
msg_ok "Created service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt -y autoremove
$STD apt -y autoclean
$STD apt -y clean
msg_ok "Cleaned"
