#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# Co-Author: remz1337
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
  curl \
  sudo \
  mc \
  gpg \
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
  libmaxminddb0
msg_ok "Installed Dependencies"

msg_info "Installing yq"
YQ_LATEST="$(wget -qO- "https://api.github.com/repos/mikefarah/yq/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')"
$STD wget "https://github.com/mikefarah/yq/releases/download/${YQ_LATEST}/yq_linux_amd64" -qO /usr/bin/yq
chmod +x /usr/bin/yq
msg_ok "Installed yq"

msg_info "Installing Python 3.12"
wget -q https://www.python.org/ftp/python/3.12.1/Python-3.12.1.tgz -O Python.tgz
tar -zxf Python.tgz
cd Python-3.12.1
$STD ./configure --enable-optimizations
$STD make altinstall
$STD cd -
$STD rm -rf Python-3.12.1
$STD rm -rf Python.tgz
$STD update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.12 1
msg_ok "Installed Python 3.12"

NODE_VER="22"
msg_info "Installing Node.js ${NODE_VER}"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VER}.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js ${NODE_VER}"

msg_info "Installing Golang"
cd ~
set +o pipefail
GO_RELEASE=$(curl -s https://go.dev/dl/ | grep -o -m 1 "go.*\linux-amd64.tar.gz")
$STD wget -q https://golang.org/dl/${GO_RELEASE}
tar -xzf ${GO_RELEASE} -C /usr/local
$STD ln -s /usr/local/go/bin/go /usr/bin/go
rm -rf go/
rm -rf ${GO_RELEASE}
set -o pipefail
msg_ok "Installed Golang"

msg_info "Building Authentik website"
RELEASE=$(curl -s https://api.github.com/repos/goauthentik/authentik/releases/latest | grep "tarball_url" | awk '{print substr($2, 2, length($2)-3)}')
mkdir -p /opt/authentik
$STD wget -qO authentik.tar.gz "${RELEASE}"
tar -xzf authentik.tar.gz -C /opt/authentik --strip-components 1 --overwrite
rm -rf authentik.tar.gz
cd /opt/authentik/website
$STD npm install
$STD npm run build-bundled
cd /opt/authentik/web
$STD npm install
$STD npm run build
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt
msg_ok "Built Authentik website"

msg_info "Building Go Proxy"
cd /opt/authentik
$STD go mod download
$STD go build -o /go/authentik ./cmd/server
$STD go build -o /opt/authentik/authentik-server /opt/authentik/cmd/server/
msg_ok "Built Go Proxy"

msg_info "Installing GeoIP"
cd ~
GEOIP_RELEASE=$(curl -s https://api.github.com/repos/maxmind/geoipupdate/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
$STD wget -qO geoipupdate.deb https://github.com/maxmind/geoipupdate/releases/download/v${GEOIP_RELEASE}/geoipupdate_${GEOIP_RELEASE}_linux_amd64.deb
$STD dpkg -i geoipupdate.deb
rm geoipupdate.deb
cat <<EOF >/etc/GeoIP.conf
#GEOIPUPDATE_EDITION_IDS="GeoLite2-City GeoLite2-ASN"
#GEOIPUPDATE_VERBOSE="1"
#GEOIPUPDATE_ACCOUNT_ID_FILE="/run/secrets/GEOIPUPDATE_ACCOUNT_ID"
#GEOIPUPDATE_LICENSE_KEY_FILE="/run/secrets/GEOIPUPDATE_LICENSE_KEY"
EOF
msg_ok "Installed GeoIP"

msg_info "Installing Python Dependencies"
cd /opt/authentik
$STD apt install -y python3-pip
$STD apt install -y git
$STD pip3 install --upgrade pip
$STD pip3 install poetry poetry-plugin-export
$STD ln -s /usr/local/bin/poetry /usr/bin/poetry
$STD poetry install --only=main --no-ansi --no-interaction --no-root
$STD poetry export --without-hashes --without-urls -f requirements.txt --output requirements.txt
$STD pip install --no-cache-dir -r requirements.txt
$STD pip install .
msg_ok "Installed Python Dependencies"

msg_info "Installing Redis"
$STD apt install -y redis-server
systemctl enable -q --now redis-server
msg_ok "Installed Redis"

msg_info "Installing PostgreSQL"
$STD apt install -y postgresql postgresql-contrib
DB_NAME="authentik"
DB_USER="authentik"
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 
$STD sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
$STD sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
msg_ok "Installed PostgreSQL"

msg_info "Installing Authentik"
mkdir -p /etc/authentik
cp /opt/authentik/authentik/lib/default.yml /opt/authentik/authentik/lib/default.yml.BAK
mv /opt/authentik/authentik/lib/default.yml /etc/authentik/config.yml
$STD yq -i ".secret_key = \"$(openssl rand -hex 32)\"" /etc/authentik/config.yml
$STD yq -i ".postgresql.password = \"${DB_PASS}\"" /etc/authentik/config.yml
$STD yq -i ".geoip = \"/opt/authentik/tests/GeoLite2-City-Test.mmdb\"" /etc/authentik/config.yml
cp -r /opt/authentik/authentik/blueprints /opt/authentik/blueprints
$STD yq -i ".blueprints_dir = \"/opt/authentik/blueprints\"" /etc/authentik/config.yml
$STD apt install -y python-is-python3
$STD ln -s /usr/local/bin/gunicorn /usr/bin/gunicorn
$STD ln -s /usr/local/bin/celery /usr/bin/celery
cd /opt/authentik
$STD bash /opt/authentik/lifecycle/ak migrate
msg_ok "Installed Authentik"

msg_info "Configuring Services"
cat <<EOF >/etc/systemd/system/authentik-server.service
[Unit]
Description = Authentik Server
[Service]
ExecStart=/opt/authentik/authentik-server
WorkingDirectory=/opt/authentik/
#User=authentik
#Group=authentik
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now authentik-server
sleep 2
cat <<EOF >/etc/systemd/system/authentik-worker.service
[Unit]
Description = Authentik Worker
[Service]
Environment=DJANGO_SETTINGS_MODULE="authentik.root.settings"
ExecStart=celery -A authentik.root.celery worker -Ofair --max-tasks-per-child=1 --autoscale 3,1 -E -B -s /tmp/celerybeat-schedule -Q authentik,authentik_scheduled,authentik_events
WorkingDirectory=/opt/authentik/authentik
#User=authentik
#Group=authentik
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now authentik-worker
sleep 5
msg_ok "Configured Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"