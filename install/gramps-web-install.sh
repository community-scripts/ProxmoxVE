#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.grampsweb.org/ | Github: https://github.com/gramps-project/gramps-web

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  appstream \
  build-essential \
  ffmpeg \
  gettext \
  gobject-introspection \
  gir1.2-gexiv2-0.10 \
  gir1.2-gtk-3.0 \
  gir1.2-osmgpsmap-1.0 \
  gir1.2-pango-1.0 \
  git \
  graphviz \
  libcairo2-dev \
  libgirepository1.0-dev \
  libglib2.0-dev \
  libicu-dev \
  libopencv-dev \
  pkg-config \
  poppler-utils \
  python3-dev \
  tesseract-ocr
msg_ok "Installed Dependencies"

PYTHON_VERSION="3.12" setup_uv
NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "gramps-web-api" "gramps-project/gramps-web-api" "tarball" "latest" "/opt/gramps-web-api"
fetch_and_deploy_gh_release "gramps-web" "gramps-project/gramps-web" "tarball" "latest" "/opt/gramps-web/frontend"

msg_info "Setting up Gramps Web"
mkdir -p \
  /opt/gramps-web/config \
  /opt/gramps-web/data/cache/export \
  /opt/gramps-web/data/cache/persistent \
  /opt/gramps-web/data/cache/report \
  /opt/gramps-web/data/cache/request \
  /opt/gramps-web/data/cache/thumbnail \
  /opt/gramps-web/data/gramps/grampsdb \
  /opt/gramps-web/data/indexdir \
  /opt/gramps-web/data/media \
  /opt/gramps-web/data/users

SECRET_KEY="$(openssl rand -hex 32)"
cat <<EOF >/opt/gramps-web/config/config.cfg
TREE="Gramps Web"
SECRET_KEY="${SECRET_KEY}"
BASE_URL="http://${LOCAL_IP}:5000"
USER_DB_URI="sqlite:////opt/gramps-web/data/users/users.sqlite"
SEARCH_INDEX_DB_URI="sqlite:////opt/gramps-web/data/indexdir/search_index.db"
MEDIA_BASE_DIR="/opt/gramps-web/data/media"
STATIC_PATH="/opt/gramps-web/frontend/dist"
THUMBNAIL_CACHE_CONFIG={"CACHE_TYPE":"FileSystemCache","CACHE_DIR":"/opt/gramps-web/data/cache/thumbnail","CACHE_THRESHOLD":1000,"CACHE_DEFAULT_TIMEOUT":0}
REQUEST_CACHE_CONFIG={"CACHE_TYPE":"FileSystemCache","CACHE_DIR":"/opt/gramps-web/data/cache/request","CACHE_THRESHOLD":1000,"CACHE_DEFAULT_TIMEOUT":0}
PERSISTENT_CACHE_CONFIG={"CACHE_TYPE":"FileSystemCache","CACHE_DIR":"/opt/gramps-web/data/cache/persistent","CACHE_THRESHOLD":0,"CACHE_DEFAULT_TIMEOUT":0}
REPORT_DIR="/opt/gramps-web/data/cache/report"
EXPORT_DIR="/opt/gramps-web/data/cache/export"
EOF
$STD uv venv -c -p python3.12 /opt/gramps-web/venv
source /opt/gramps-web/venv/bin/activate
$STD uv pip install --no-cache-dir --upgrade pip setuptools wheel
$STD uv pip install --no-cache-dir gunicorn
$STD uv pip install --no-cache-dir /opt/gramps-web-api
cd /opt/gramps-web/frontend
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
$STD corepack enable
$STD npm install
$STD npm run build
cd /opt/gramps-web-api
GRAMPS_API_CONFIG=/opt/gramps-web/config/config.cfg \
  ALEMBIC_CONFIG=/opt/gramps-web-api/alembic.ini \
  GRAMPSHOME=/opt/gramps-web/data/gramps \
  GRAMPS_DATABASE_PATH=/opt/gramps-web/data/gramps/grampsdb \
  $STD /opt/gramps-web/venv/bin/python3 -m gramps_webapi user migrate
msg_ok "Set up Gramps Web"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/gramps-web.service
[Unit]
Description=Gramps Web Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/gramps-web-api
Environment=GRAMPS_API_CONFIG=/opt/gramps-web/config/config.cfg
Environment=GRAMPSHOME=/opt/gramps-web/data/gramps
Environment=GRAMPS_DATABASE_PATH=/opt/gramps-web/data/gramps/grampsdb
Environment=PATH=/opt/gramps-web/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/opt/gramps-web/venv/bin/gunicorn -w 2 -b 0.0.0.0:5000 gramps_webapi.wsgi:app --timeout 120 --limit-request-line 8190
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now gramps-web
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
