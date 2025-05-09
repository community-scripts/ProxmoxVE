#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://goauthentik.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (Patience)"
$STD apt-get install -y \
  pkg-config \
  libffi-dev \
  build-essential \
  libpq-dev \
  libkrb5-dev \
  libssl-dev \
  libsqlite3-dev \
  tk-dev \
  libgdbm-dev \
  libc6-dev \
  libbz2-dev \
  zlib1g-dev \
  libxmlsec1 \
  libxmlsec1-dev \
  libxmlsec1-openssl \
  libmaxminddb0 \
  python3-pip \
  redis-server \
  git
msg_ok "Installed Dependencies"

setup_uv
PG_VERSION="16" install_postgresql
NODE_VERSION="22" install_node_and_modules
install_go

msg_info "Installing yq"
cd /tmp
YQ_LATEST="$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')"
curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_LATEST}/yq_linux_amd64" -o /usr/bin/yq
chmod +x /usr/bin/yq
msg_ok "Installed yq"

msg_info "Installing GeoIP"
cd /tmp
GEOIP_RELEASE=$(curl -fsSL https://api.github.com/repos/maxmind/geoipupdate/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/maxmind/geoipupdate/releases/download/v${GEOIP_RELEASE}/geoipupdate_${GEOIP_RELEASE}_linux_amd64.deb" -o "geoipupdate.deb"
$STD dpkg -i geoipupdate.deb
cat <<EOF >/etc/GeoIP.conf
#GEOIPUPDATE_EDITION_IDS="GeoLite2-City GeoLite2-ASN"
#GEOIPUPDATE_VERBOSE="1"
#GEOIPUPDATE_ACCOUNT_ID_FILE="/run/secrets/GEOIPUPDATE_ACCOUNT_ID"
#GEOIPUPDATE_LICENSE_KEY_FILE="/run/secrets/GEOIPUPDATE_LICENSE_KEY"
EOF
msg_ok "Installed GeoIP"

msg_info "Installing PostgreSQL"
$STD apt-get install -y postgresql-16 postgresql-contrib-16
DB_NAME="authentik"
DB_USER="authentik"
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
$STD sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
$STD sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
msg_ok "Installed PostgreSQL"

msg_info "Installing authentik"
RELEASE=$(curl -fsSL https://api.github.com/repos/goauthentik/authentik/releases/latest | grep "tarball_url" | awk '{print substr($2, 2, length($2)-3)}')
mkdir -p /opt/authentik
curl -fsSL "${RELEASE}" -o "authentik.tar.gz"
tar -xzf authentik.tar.gz -C /opt/authentik --strip-components 1 --overwrite
export NODE_OPTIONS="--max-old-space-size=4096"
cd /opt/authentik/website
$STD npm install
$STD npm run build-bundled

cd /opt/authentik/web
$STD npm install
$STD npm run build

cd /opt/authentik
$STD go mod download
$STD go build -o /go/authentik ./cmd/server
$STD go build -o /opt/authentik/authentik-server /opt/authentik/cmd/server/
$STD uv sync --frozen --no-install-project --no-dev
#$STD pip3 install --no-cache-dir --upgrade pip
#$STD pip3 install --upgrade pip
#$STD pip3 install poetry poetry-plugin-export

#ln -s /usr/local/bin/poetry /usr/bin/poetry
#$STD poetry install --only=main --no-ansi --no-interaction --no-root
#$STD poetry export --without-hashes --without-urls -f requirements.txt --output requirements.txt
#$STD pip install --no-cache-dir -r requirements.txt
#$STD pip install .
mkdir -p /etc/authentik
mv /opt/authentik/authentik/lib/default.yml /etc/authentik/config.yml
$STD yq -i ".secret_key = \"$(openssl rand -hex 32)\"" /etc/authentik/config.yml
$STD yq -i ".postgresql.password = \"${DB_PASS}\"" /etc/authentik/config.yml
$STD yq -i ".geoip = \"/opt/authentik/tests/GeoLite2-City-Test.mmdb\"" /etc/authentik/config.yml
cp -r /opt/authentik/authentik/blueprints /opt/authentik/blueprints
$STD yq -i ".blueprints_dir = \"/opt/authentik/blueprints\"" /etc/authentik/config.yml
#ln -s /usr/bin/python3 /usr/bin/python
#ln -s /usr/local/bin/gunicorn /usr/bin/gunicorn
#ln -s /usr/local/bin/celery /usr/bin/celery
#$STD bash /opt/authentik/lifecycle/ak migrate
cd /opt/authentik
uv run python -m lifecycle.migrate
ln -s /opt/authentik/.venv/bin/gunicorn /usr/local/bin/gunicorn
ln -s /opt/authentik/.venv/bin/celery /usr/local/bin/celery
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Installed authentik"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/authentik-server.service
[Unit]
Description=authentik Go Server (API Gateway)
After=network.target
Wants=redis.service postgresql.service

[Service]
WorkingDirectory=/opt/authentik/
ExecStart=/opt/authentik/authentik-server
Restart=always
RestartSec=5
Environment=DJANGO_SETTINGS_MODULE=authentik.root.settings

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/authentik-worker.service
[Unit]
Description=authentik Celery Worker
After=network.target redis.service postgresql.service
Requires=redis.service

[Service]
Type=simple
WorkingDirectory=/opt/authentik
ExecStart=/opt/authentik/.venv/bin/celery \
  -A authentik.root.celery worker \
  -Ofair \
  --max-tasks-per-child=1 \
  --autoscale 3,1 \
  -Q authentik,authentik_scheduled,authentik_events \
  -E
Restart=always
RestartSec=5
Environment=DJANGO_SETTINGS_MODULE=authentik.root.settings

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/etc/systemd/system/authentik-celery-beat.service
[Unit]
Description=authentik Celery Beat Scheduler
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/authentik
ExecStart=/opt/authentik/.venv/bin/celery \
  -A authentik.root.celery beat \
  -s /tmp/celerybeat-schedule
Restart=always
RestartSec=5
#User=authentik
Environment=DJANGO_SETTINGS_MODULE=authentik.root.settings

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now authentik-server authentik-worker authentik-celery-beat
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf /tmp/Python-3.12.1
rm -rf /tmp/Python.tgz
rm -rf go/
rm -rf /tmp/geoipupdate.deb
rm -rf authentik.tar.gz
$STD apt-get -y remove yq
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
