#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/simple-login/app

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
echo "postfix postfix/mailname string $(hostname -f)" | debconf-set-selections
echo "postfix postfix/main_mailer_type string Internet Site" | debconf-set-selections
$STD apt install -y \
  build-essential \
  libre2-dev \
  pkg-config \
  libpq-dev \
  cmake \
  ninja-build \
  clang \
  redis-server \
  nginx \
  postfix \
  postfix-pgsql \
  opendkim-tools
msg_ok "Installed Dependencies"

PG_VERSION="17" setup_postgresql
APPLICATION="simplelogin" PG_DB_NAME="simplelogin" PG_DB_USER="simplelogin" setup_postgresql_db
PYTHON_VERSION="3.12" setup_uv
NODE_VERSION="24" setup_nodejs

fetch_and_deploy_gh_release "simplelogin" "simple-login/app"

msg_info "Installing SimpleLogin (Patience)"
cd /opt/simplelogin
$STD uv venv
$STD uv pip install setuptools hatchling editables
export CMAKE_POLICY_VERSION_MINIMUM=3.5
$STD uv sync --locked --no-dev --no-build-isolation --no-install-package newrelic
if [[ -f /opt/simplelogin/static/package.json ]]; then
  cd /opt/simplelogin/static
  $STD npm ci
fi
msg_ok "Installed SimpleLogin"

msg_info "Configuring SimpleLogin"
FLASK_SECRET=$(openssl rand -hex 32)

mkdir -p /opt/simplelogin/dkim
$STD openssl genrsa -traditional -out /opt/simplelogin/dkim/dkim.private 2048
$STD openssl rsa -in /opt/simplelogin/dkim/dkim.private -pubout -out /opt/simplelogin/dkim/dkim.public.key
DKIM_PUB=$(openssl rsa -in /opt/simplelogin/dkim/dkim.private -pubout 2>/dev/null | grep -v '^-----' | tr -d '\n')
cat <<EOF >/opt/simplelogin/dkim/dkim.dns.txt
dkim._domainkey.EMAIL_DOMAIN. IN TXT ( "v=DKIM1; k=rsa; p=${DKIM_PUB}" )
EOF
$STD openssl genrsa -out /opt/simplelogin/openid-rsa.key 2048
$STD openssl rsa -in /opt/simplelogin/openid-rsa.key -pubout -out /opt/simplelogin/openid-rsa.pub

mkdir -p /opt/simplelogin/uploads /opt/simplelogin/.gnupg
chmod 700 /opt/simplelogin/.gnupg

{
  echo "URL=http://${LOCAL_IP}"
  echo "EMAIL_DOMAIN=example.com"
  echo "SUPPORT_EMAIL=support@example.com"
  echo 'EMAIL_SERVERS_WITH_PRIORITY=[(10, "localhost.")]'
  echo "POSTFIX_SERVER=localhost"
  echo "DB_URI=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost/${PG_DB_NAME}"
  echo "FLASK_SECRET=${FLASK_SECRET}"
  echo "DKIM_PRIVATE_KEY_PATH=/opt/simplelogin/dkim/dkim.private"
  echo "GNUPGHOME=/opt/simplelogin/.gnupg"
  echo "LOCAL_FILE_UPLOAD=true"
  echo "UPLOAD_DIR=/opt/simplelogin/uploads"
  echo "DISABLE_ALIAS_SUFFIX=1"
  echo "WORDS_FILE_PATH=/opt/simplelogin/local_data/words.txt"
  echo "NAMESERVERS=1.1.1.1"
  echo "MEM_STORE_URI=redis://localhost:6379/1"
  echo "OPENID_PRIVATE_KEY_PATH=/opt/simplelogin/openid-rsa.key"
  echo "OPENID_PUBLIC_KEY_PATH=/opt/simplelogin/openid-rsa.pub"
  echo "METRICS_BACKENDS=noop"
} >/opt/simplelogin/.env

cd /opt/simplelogin
export FLASK_APP=server
export URL="http://${LOCAL_IP}"
export EMAIL_DOMAIN="example.com"
export SUPPORT_EMAIL="support@example.com"
export EMAIL_SERVERS_WITH_PRIORITY='[(10, "localhost.")]'
export POSTFIX_SERVER="localhost"
export DB_URI="postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost/${PG_DB_NAME}"
export FLASK_SECRET="${FLASK_SECRET}"
export DKIM_PRIVATE_KEY_PATH="/opt/simplelogin/dkim/dkim.private"
export GNUPGHOME="/opt/simplelogin/.gnupg"
export LOCAL_FILE_UPLOAD="true"
export UPLOAD_DIR="/opt/simplelogin/uploads"
export DISABLE_ALIAS_SUFFIX="1"
export WORDS_FILE_PATH="/opt/simplelogin/local_data/words.txt"
export NAMESERVERS="1.1.1.1"
export MEM_STORE_URI="redis://localhost:6379/1"
export OPENID_PRIVATE_KEY_PATH="/opt/simplelogin/openid-rsa.key"
export OPENID_PUBLIC_KEY_PATH="/opt/simplelogin/openid-rsa.pub"
export METRICS_BACKENDS="noop"
$STD .venv/bin/alembic upgrade head
$STD .venv/bin/python init_app.py
msg_ok "Configured SimpleLogin"

msg_info "Configuring Postfix"
cat <<EOF >/etc/postfix/pgsql-relay-domains.cf
hosts = localhost
dbname = ${PG_DB_NAME}
user = ${PG_DB_USER}
password = ${PG_DB_PASS}
query = SELECT domain FROM custom_domain WHERE domain='%s' AND verified=true
EOF

cat <<EOF >/etc/postfix/pgsql-transport-maps.cf
hosts = localhost
dbname = ${PG_DB_NAME}
user = ${PG_DB_USER}
password = ${PG_DB_PASS}
query = SELECT 'smtp:[127.0.0.1]:20381' FROM custom_domain WHERE domain='%s' AND verified=true
EOF

chmod 640 /etc/postfix/pgsql-*.cf

cat <<EOF >/etc/postfix/transport
example.com smtp:[127.0.0.1]:20381
EOF
$STD postmap /etc/postfix/transport

postconf -e "relay_domains = example.com, pgsql:/etc/postfix/pgsql-relay-domains.cf"
postconf -e "transport_maps = hash:/etc/postfix/transport, pgsql:/etc/postfix/pgsql-transport-maps.cf"
postconf -e "smtpd_recipient_restrictions = permit_mynetworks, reject_unauth_destination"
postconf -e "inet_protocols = ipv4"
$STD systemctl restart postfix
msg_ok "Configured Postfix"

msg_info "Creating Services"
cat <<'EOF' >/etc/systemd/system/simplelogin-webapp.service
[Unit]
Description=SimpleLogin Web Application
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/simplelogin
EnvironmentFile=/opt/simplelogin/.env
ExecStart=/opt/simplelogin/.venv/bin/gunicorn wsgi:app -b 127.0.0.1:7777 -w 2 --timeout 120
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<'EOF' >/etc/systemd/system/simplelogin-email.service
[Unit]
Description=SimpleLogin Email Handler
After=network.target postgresql.service redis-server.service postfix.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/simplelogin
EnvironmentFile=/opt/simplelogin/.env
ExecStart=/opt/simplelogin/.venv/bin/python email_handler.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat <<'EOF' >/etc/systemd/system/simplelogin-job.service
[Unit]
Description=SimpleLogin Job Runner
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/simplelogin
EnvironmentFile=/opt/simplelogin/.env
ExecStart=/opt/simplelogin/.venv/bin/python job_runner.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now redis-server simplelogin-webapp simplelogin-email simplelogin-job
msg_ok "Created Services"

msg_info "Configuring Nginx"
cat <<'EOF' >/etc/nginx/sites-available/simplelogin.conf
server {
  listen 80 default_server;
  server_name _;

  client_max_body_size 10M;

  location / {
    proxy_pass http://127.0.0.1:7777;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
EOF
ln -sf /etc/nginx/sites-available/simplelogin.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
$STD nginx -t
$STD systemctl enable --now nginx
$STD systemctl reload nginx
msg_ok "Configured Nginx"

motd_ssh
customize
cleanup_lxc
