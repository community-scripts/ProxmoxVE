#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y --no-install-recommends \
  redis \
  postgresql \
  build-essential \
  imagemagick \
  fonts-liberation \
  optipng \
  gnupg \
  libpq-dev \
  libmagic-dev \
  mime-support \
  libzbar0 \
  poppler-utils \
  default-libmysqlclient-dev \
  automake \
  libtool \
  pkg-config \
  git \
  curl \
  libtiff-dev \
  libpng-dev \
  libleptonica-dev \
  sudo \
  mc
msg_ok "Installed Dependencies"

msg_info "Installing Python3 Dependencies (Patience)"
$STD apt-get install -y --no-install-recommends \
  python3 \
  python3-pip \
  python3-dev \
  python3-setuptools \
  python3-wheel
msg_ok "Installed Python3 Dependencies"

msg_info "Installing OCR Dependencies (Patience)"
$STD apt-get install -y --no-install-recommends \
  unpaper \
  icc-profiles-free \
  qpdf \
  liblept5 \
  libxml2 \
  pngquant \
  zlib1g \
  tesseract-ocr \
  tesseract-ocr-eng
  
cd /tmp
wget -q https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10040/ghostscript-10.04.0.tar.gz
$STD tar -xzf ghostscript-10.04.0.tar.gz
cd ghostscript-10.04.0
$STD ./configure
$STD make
$STD sudo make install
msg_ok "Installed OCR Dependencies"

msg_info "Installing JBIG2"
$STD git clone https://github.com/ie13/jbig2enc /opt/jbig2enc
cd /opt/jbig2enc
$STD bash ./autogen.sh
$STD bash ./configure
$STD make
$STD make install
rm -rf /opt/jbig2enc
msg_ok "Installed JBIG2"

msg_info "Installing Paperless-ngx (Patience)"
Paperlessngx=$(wget -q https://github.com/paperless-ngx/paperless-ngx/releases/latest -O - | grep "title>Release" | cut -d " " -f 5)
cd /opt
$STD wget https://github.com/paperless-ngx/paperless-ngx/releases/download/$Paperlessngx/paperless-ngx-$Paperlessngx.tar.xz
$STD tar -xf paperless-ngx-$Paperlessngx.tar.xz -C /opt/
mv paperless-ngx paperless
rm paperless-ngx-$Paperlessngx.tar.xz
cd /opt/paperless
$STD pip install --upgrade pip
$STD pip install -r requirements.txt
curl -s -o /opt/paperless/paperless.conf https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/main/paperless.conf.example
mkdir -p {consume,data,media,static}
sed -i -e 's|#PAPERLESS_REDIS=redis://localhost:6379|PAPERLESS_REDIS=redis://localhost:6379|' /opt/paperless/paperless.conf
sed -i -e "s|#PAPERLESS_CONSUMPTION_DIR=../consume|PAPERLESS_CONSUMPTION_DIR=/opt/paperless/consume|" /opt/paperless/paperless.conf
sed -i -e "s|#PAPERLESS_DATA_DIR=../data|PAPERLESS_DATA_DIR=/opt/paperless/data|" /opt/paperless/paperless.conf
sed -i -e "s|#PAPERLESS_MEDIA_ROOT=../media|PAPERLESS_MEDIA_ROOT=/opt/paperless/media|" /opt/paperless/paperless.conf
sed -i -e "s|#PAPERLESS_STATICDIR=../static|PAPERLESS_STATICDIR=/opt/paperless/static|" /opt/paperless/paperless.conf
echo "${Paperlessngx}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed Paperless-ngx"

msg_info "Installing Natural Language Toolkit (Patience)"
$STD python3 -m nltk.downloader -d /usr/share/nltk_data all
msg_ok "Installed Natural Language Toolkit"

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
sed -i -e 's|#PAPERLESS_DBHOST=localhost|PAPERLESS_DBHOST=localhost|' /opt/paperless/paperless.conf
sed -i -e 's|#PAPERLESS_DBPORT=5432|PAPERLESS_DBPORT=5432|' /opt/paperless/paperless.conf
sed -i -e "s|#PAPERLESS_DBNAME=paperless|PAPERLESS_DBNAME=$DB_NAME|" /opt/paperless/paperless.conf
sed -i -e "s|#PAPERLESS_DBUSER=paperless|PAPERLESS_DBUSER=$DB_USER|" /opt/paperless/paperless.conf
sed -i -e "s|#PAPERLESS_DBPASS=paperless|PAPERLESS_DBPASS=$DB_PASS|" /opt/paperless/paperless.conf
sed -i -e "s|#PAPERLESS_SECRET_KEY=change-me|PAPERLESS_SECRET_KEY=$SECRET_KEY|" /opt/paperless/paperless.conf
cd /opt/paperless/src
$STD python3 manage.py migrate
msg_ok "Set up PostgreSQL database"

read -r -p "Would you like to add Adminer? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing Adminer"
  $STD apt install -y adminer
  $STD a2enconf adminer
  systemctl reload apache2
  IP=$(hostname -I | awk '{print $1}')
  echo "" >>~/paperless.creds
  echo -e "Adminer Interface: \e[32m$IP/adminer/\e[0m" >>~/paperless.creds
  echo -e "Adminer System: \e[32mPostgreSQL\e[0m" >>~/paperless.creds
  echo -e "Adminer Server: \e[32mlocalhost:5432\e[0m" >>~/paperless.creds
  echo -e "Adminer Username: \e[32m$DB_USER\e[0m" >>~/paperless.creds
  echo -e "Adminer Password: \e[32m$DB_PASS\e[0m" >>~/paperless.creds
  echo -e "Adminer Database: \e[32m$DB_NAME\e[0m" >>~/paperless.creds
  msg_ok "Installed Adminer"
fi

msg_info "Setting up admin Paperless-ngx User & Password"
## From https://github.com/linuxserver/docker-paperless-ngx/blob/main/root/etc/cont-init.d/99-migrations
cat <<EOF | python3 /opt/paperless/src/manage.py shell
from django.contrib.auth import get_user_model
UserModel = get_user_model()
user = UserModel.objects.create_user('admin', password='$DB_PASS')
user.is_superuser = True
user.is_staff = True
user.save()
EOF
echo "" >>~/paperless.creds
echo -e "Paperless-ngx WebUI User: \e[32madmin\e[0m" >>~/paperless.creds
echo -e "Paperless-ngx WebUI Password: \e[32m$DB_PASS\e[0m" >>~/paperless.creds
echo "" >>~/paperless.creds
msg_ok "Set up admin Paperless-ngx User & Password"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/paperless-scheduler.service
[Unit]
Description=Paperless Celery beat
Requires=redis.service

[Service]
WorkingDirectory=/opt/paperless/src
ExecStart=celery --app paperless beat --loglevel INFO

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
ExecStart=celery --app paperless worker --loglevel INFO

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/paperless-consumer.service
[Unit]
Description=Paperless consumer
Requires=redis.service

[Service]
WorkingDirectory=/opt/paperless/src
ExecStart=python3 manage.py document_consumer

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
ExecStart=/usr/local/bin/gunicorn -c /opt/paperless/gunicorn.conf.py paperless.asgi:application

[Install]
WantedBy=multi-user.target
EOF

sed -i -e 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml

systemctl daemon-reload
$STD systemctl enable --now paperless-consumer paperless-webserver paperless-scheduler paperless-task-queue.service
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/paperless/docker
rm -rf /tmp/ghostscript*
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
