#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.paperless-ngx.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
  redis \
  build-essential \
  imagemagick \
  fonts-liberation \
  optipng \
  libpq-dev \
  libmagic-dev \
  mime-support \
  libzbar0 \
  poppler-utils \
  default-libmysqlclient-dev \
  automake \
  libtool \
  pkg-config \
  libtiff-dev \
  libpng-dev \
  libleptonica-dev
msg_ok "Installed Dependencies"

PG_VERSION="16" setup_postgresql
PYTHON_VERSION="3.13" setup_uv
fetch_and_deploy_gh_release "paperless" "paperless-ngx/paperless-ngx" "prebuild" "latest" "/opt/paperless" "paperless*tar.xz"
fetch_and_deploy_gh_release "jbig2enc" "ie13/jbig2enc" "tarball" "latest" "/opt/jbig2enc"
setup_gs

msg_info "Installing OCR Dependencies (Patience)"
$STD apt-get install -y \
  unpaper \
  icc-profiles-free \
  qpdf \
  liblept5 \
  libxml2 \
  pngquant \
  zlib1g \
  tesseract-ocr \
  tesseract-ocr-eng
$STD sudo make install
msg_ok "Installed OCR Dependencies"

msg_info "Setup JBIG2"
cd /opt/jbig2enc
$STD bash ./autogen.sh
$STD bash ./configure
$STD make
$STD make install
rm -rf /opt/jbig2enc
msg_ok "Installed JBIG2"

msg_info "Setting up PostgreSQL database"
DB_NAME=paperlessdb
DB_USER=paperless
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
SECRET_KEY="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)"
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER ENCODING 'UTF8' TEMPLATE template0;"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET client_encoding TO 'utf8';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';"
$STD sudo -u postgres psql -c "ALTER ROLE $DB_USER SET timezone TO 'UTC'"
echo "" >>~/paperless.creds
echo -e "Paperless-ngx Database User: \e[32m$DB_USER\e[0m" >>~/paperless.creds
echo -e "Paperless-ngx Database Password: \e[32m$DB_PASS\e[0m" >>~/paperless.creds
echo -e "Paperless-ngx Database Name: \e[32m$DB_NAME\e[0m" >>~/paperless.creds

msg_info "Installing Natural Language Toolkit (Patience)"
$STD uv run -- python -m nltk.downloader -d /usr/share/nltk_data all
sed -i -e 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml
msg_ok "Installed Natural Language Toolkit"

msg_info "Setup Paperless-ngx"
cd /opt/paperless
$STD uv sync --all-extras
curl -fsSL "https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/main/paperless.conf.example" -o /opt/paperless/paperless.conf
mkdir -p {consume,data,media,static}
sed -i \
  -e 's|#PAPERLESS_REDIS=redis://localhost:6379|PAPERLESS_REDIS=redis://localhost:6379|' \
  -e "s|#PAPERLESS_CONSUMPTION_DIR=../consume|PAPERLESS_CONSUMPTION_DIR=/opt/paperless/consume|" \
  -e "s|#PAPERLESS_DATA_DIR=../data|PAPERLESS_DATA_DIR=/opt/paperless/data|" \
  -e "s|#PAPERLESS_MEDIA_ROOT=../media|PAPERLESS_MEDIA_ROOT=/opt/paperless/media|" \
  -e "s|#PAPERLESS_STATICDIR=../static|PAPERLESS_STATICDIR=/opt/paperless/static|" \
  -e 's|#PAPERLESS_DBHOST=localhost|PAPERLESS_DBHOST=localhost|' \
  -e 's|#PAPERLESS_DBPORT=5432|PAPERLESS_DBPORT=5432|' \
  -e "s|#PAPERLESS_DBNAME=paperless|PAPERLESS_DBNAME=$DB_NAME|" \
  -e "s|#PAPERLESS_DBUSER=paperless|PAPERLESS_DBUSER=$DB_USER|" \
  -e "s|#PAPERLESS_DBPASS=paperless|PAPERLESS_DBPASS=$DB_PASS|" \
  -e "s|#PAPERLESS_SECRET_KEY=change-me|PAPERLESS_SECRET_KEY=$SECRET_KEY|" \
  /opt/paperless/paperless.conf
cd /opt/paperless/src
$STD uv run -- python manage.py migrate
msg_ok "Setup Paperless-ngx"

msg_info "Setting up admin Paperless-ngx User & Password"
cat <<EOF | uv run -- python /opt/paperless/src/manage.py shell
from django.contrib.auth import get_user_model
UserModel = get_user_model()
user = UserModel.objects.create_user('admin', password='$DB_PASS')
user.is_superuser = True
user.is_staff = True
user.save()
EOF
{
  echo "Paperless-ngx-Credentials"
  echo "Paperless-ngx Database Name: $DB_NAME"
  echo "Paperless-ngx Database User: $DB_USER"
  echo "Paperless-ngx Database Password: $DB_PASS"
  echo "Paperless-ngx Secret Key: $SECRET_KEY\n"
  echo "Paperless-ngx WebUI User: admin"
  echo "Paperless-ngx WebUI Password: $DB_PASS"
} >>~/paperless-ngx.creds
msg_ok "Set up admin Paperless-ngx User & Password"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/paperless-scheduler.service
[Unit]
Description=Paperless Celery beat
Requires=redis.service

[Service]
WorkingDirectory=/opt/paperless/src
ExecStart=uv run -- celery --app paperless beat --loglevel INFO

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/paperless-task-queue.service
[Unit]
Description=Paperless Celery Workers
Requires=redis.service
After=postgresql.service

[Service]
WorkingDirectory=/opt/paperless/src
ExecStart=uv run -- celery --app paperless worker --loglevel INFO

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/paperless-consumer.service
[Unit]
Description=Paperless consumer
Requires=redis.service

[Service]
WorkingDirectory=/opt/paperless/src
ExecStartPre=/bin/sleep 2
ExecStart=uv run -- python manage.py document_consumer

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/paperless-webserver.service
[Unit]
Description=Paperless webserver
After=network.target
Wants=network.target
Requires=redis.service

[Service]
WorkingDirectory=/opt/paperless/src
ExecStart=uv run -- granian --interface asginl --ws "paperless.asgi:application"
Environment=GRANIAN_HOST=::
Environment=GRANIAN_PORT=8000
Environment=GRANIAN_WORKERS=1

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now paperless-webserver paperless-scheduler paperless-task-queue paperless-consumer
msg_ok "Created Services"

read -r -p "${TAB3}Would you like to add Adminer? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  setup_adminer
fi

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/paperless/docker
rm -rf /tmp/ghostscript*
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
